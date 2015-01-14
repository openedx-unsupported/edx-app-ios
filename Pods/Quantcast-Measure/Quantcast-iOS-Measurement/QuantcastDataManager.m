/*
 * © Copyright 2012-2014 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License. Unauthorized use of this file constitutes
 * copyright infringement and violation of law.
 */
#if !__has_feature(objc_arc)
#error "Quantcast Measurement is designed to be used with ARC. Please turn on ARC or add '-fobjc-arc' to this file's compiler flags"
#endif // !__has_feature(objc_arc)

#import "QuantcastDataManager.h"
#import "QuantcastUtils.h"
#import "QuantcastDatabase.h"
#import "QuantcastEvent.h"
#import "QuantcastUploadManager.h"
#import "QuantcastParameters.h"
#import "QuantcastPolicy.h"
#import "QuantcastNetworkReachability.h"

#if QCMEASUREMENT_ENABLE_JSONKIT
#import "JSONKit.h"
#endif

#ifndef QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT 
#define QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT 10000
#endif

@interface QuantcastDataManager (){
    QuantcastDatabase*  _db;
    
    QuantcastUploadManager* _uploadManager;
    
    BOOL _enableLogging;
    BOOL _isOptOut;
    BOOL _isDataDumpInprogress;
    
    NSUInteger _maxEventRetentionCount;
}

-(BOOL)setUpEventDatabaseConnection;
-(void)trimEventsDatabaseBy:(NSUInteger)inEventsToDelete;
@end

@implementation QuantcastDataManager

-(id)initWithOptOut:(BOOL)inOptOutStatus {
    self = [super init];
    
    if (self) {
        _uploadEventCount = QCMEASUREMENT_DEFAULT_UPLOAD_EVENT_COUNT;
        _backgroundUploadEventCount = QCMEASUREMENT_DEFAULT_BACKGROUND_UPLOAD_EVENT_COUNT;
        _maxEventRetentionCount = QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT;
        _isDataDumpInprogress = NO;
        
        _isOptOut = inOptOutStatus;
        
        if( !_isOptOut ){
            if (![self setUpEventDatabaseConnection]) {
                return nil;
            }
        }

        _uploadManager = nil;
    }
    
    return self;
}


-(void)enableDataUploadingWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachability {
    
    if ( nil == _uploadManager ) {
        _uploadManager = [[QuantcastUploadManager alloc] initWithReachability:inNetworkReachability];
    }
}

#pragma mark - Debugging
- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastDataManager %p: database = %@>", self, _db ];
}



#pragma mark - Measurement Database Management

#define QCSQL_CREATETABLE_EVENTS    @"create table events ( id integer primary key autoincrement, sessionId varchar not null, timestamp integer not null );"
#define QCSQL_CREATETABLE_EVENT     @"create table event ( eventid integer, name varchar not null, value varchar not null, FOREIGN KEY( eventid ) REFERENCES events ( id ) );"
#define QCSQL_CREATEINDEX_EVENT     @"create index event_eventid_idx on event (eventid);"

#define QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT   @"insert-new-event"
#define QCSQL_PREPAREDQUERY_INSERTNEWEVENT      @"INSERT INTO events (sessionId, timestamp) VALUES ( ?1, ?2 );"

#define QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS   @"insert-new-event-params"
#define QCSQL_PREPAREDQUERY_INSERTNEWEVENTPARAMS      @"INSERT INTO event (eventid, name, value) VALUES ( ?1, ?2, ?3 );"

+(void)initializeMeasurementDatabase:(QuantcastDatabase*)inDB {
    
    // first determine if this is a new database.
    
    [inDB beginDatabaseTransaction];
    [inDB executeSQL:@"PRAGMA foreign_keys = ON;"];
    [inDB executeSQL:QCSQL_CREATETABLE_EVENTS];
    [inDB executeSQL:QCSQL_CREATETABLE_EVENT];
    [inDB executeSQL:QCSQL_CREATEINDEX_EVENT];
    [inDB endDatabaseTransaction];
}

-(BOOL)setUpEventDatabaseConnection {
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPathCreatingIfNeeded];
    
    if ( nil == cacheDir) {
        return NO;
    }
    
    NSString* qcDatabasePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_DATABASE_FILENAME];
    
    BOOL isNewDB = ![[NSFileManager defaultManager] fileExistsAtPath:qcDatabasePath];
    
    
    _db = [QuantcastDatabase databaseWithFilePath:qcDatabasePath];
    
    if (isNewDB) {
        // it's a new database, set it up.
        [QuantcastDataManager initializeMeasurementDatabase:_db];
    }
    
    
    // create prepared queries
    [_db prepareQuery:QCSQL_PREPAREDQUERY_INSERTNEWEVENT withKey:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT];
    [_db prepareQuery:QCSQL_PREPAREDQUERY_INSERTNEWEVENTPARAMS withKey:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS];
    
    return YES;
}


#pragma mark - Recording Events

-(void)recordEvent:(QuantcastEvent*)inEvent withPolicy:(QuantcastPolicy *)inPolicy{
    if ( inPolicy.isMeasurementBlackedout ) {
        return;
    }
    
    [self recordEventWithoutUpload:inEvent withPolicy:inPolicy];
    [self uploadEventsWithPolicy:inPolicy];
 }

-(void)recordEventWithoutUpload:(QuantcastEvent*)inEvent withPolicy:(QuantcastPolicy *)inPolicy{
    //don't record anything if measurement it blacked out.
    if(!inPolicy.isMeasurementBlackedout){
        if ( nil == _db ) {
           QUANTCAST_LOG(@"Tried to log event %@, but there was no database connection available.", inEvent);
            return;
        }
        
        NSArray* eventInsertBoundData = [NSArray arrayWithObjects:inEvent.sessionID,[NSString stringWithFormat:@"%qi",(int64_t)[inEvent.timestamp timeIntervalSince1970]],nil];
        
        [_db beginDatabaseTransaction];
        
        [_db executePreparedQuery:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT bindingInsertData:eventInsertBoundData];
        
        int64_t eventId = [_db getLastInsertRowId];
        
        for (NSString* param in [inEvent.parameters allKeys]) {
            id valueObj = [inEvent.parameters objectForKey:param];
            NSString* valueStr = [QuantcastUtils stringFromObject:valueObj defaultValue:[valueObj description]];
            NSArray* paramsInsertBoundData = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%qi",eventId], param, valueStr, nil];
            [_db executePreparedQuery:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS bindingInsertData:paramsInsertBoundData];
        }
        
        [_db endDatabaseTransaction];
    }
}

-(void)uploadEventsWithPolicy:(QuantcastPolicy*)inPolicy {
    NSUInteger eventCount = [self eventCount];
    if ( inPolicy.hasPolicyBeenLoaded && !_isDataDumpInprogress && ( eventCount >= self.uploadEventCount || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground && eventCount >= self.backgroundUploadEventCount ) ) ) {
        [self initiateDataUploadWithPolicy:inPolicy];
    }
    else if ( eventCount >= _maxEventRetentionCount ) {
        // delete the equivalent a upload
        [self trimEventsDatabaseBy:self.uploadEventCount];
    }
}

-(void)initiateDataUploadWithPolicy:(QuantcastPolicy*)inPolicy {
    if ( _isDataDumpInprogress || !inPolicy.hasPolicyBeenLoaded) {
        return;
    }
    
    _isDataDumpInprogress = YES;
    
    NSString* uploadID = [QuantcastUtils generateUUID];
    
    NSString* jsonFilePath = [self dumpDataManagerToFileWithUploadID:uploadID withPolicy:inPolicy];
    
   QUANTCAST_LOG(@"QC Measurement: Dumped data manager to JSON file = %@",jsonFilePath);
    
    [_uploadManager initiateUploadForReadyJSONFilesWithDataManager:self];

    _isDataDumpInprogress = NO;
    
}

-(NSArray*)recordedEvents{
    return [self recordedEventsWithDeleteDBEvents:NO];
}

-(NSArray*)recordedEventsWithDeleteDBEvents:(BOOL)inDoDeleteDBEvents {

    if ( nil == _db ) {
        QUANTCAST_LOG(@"QC Measurement: Could not generate list of recorded events because there is no database connection");
        return nil;
    }
    
    
    NSMutableArray* eventList = nil;
    
    [_db beginDatabaseTransaction];
    
    NSArray* __autoreleasing dbEventList = nil;
    
    // first we move up to self.uploadEventCount records into a working table
    
    NSString* tempTableName = [self makeTempTableWithEvents:self.uploadEventCount];
    
    if( nil != tempTableName ){
        NSString* getEventsSQL = [NSString stringWithFormat:@"SELECT id, sessionId, timestamp FROM %@;", tempTableName];
        
        if ( ![_db executeSQL:getEventsSQL withResultsColumCount:3 producingResults:&dbEventList]) {
            return nil;
        }

        QUANTCAST_LOG(@"QC Measurement: Starting dump of %lu events from the event database.", (unsigned long)[dbEventList count]);
        
        eventList = [NSMutableArray arrayWithCapacity:[dbEventList count]];
        
        for ( NSArray* dbEventListRow in dbEventList ) {
            
            NSString* eventIdStr = [dbEventListRow objectAtIndex:0];
            int64_t eventId = [eventIdStr longLongValue];
            
            NSString* sessionId = [dbEventListRow objectAtIndex:1];
            NSString* eventTimeIntervalStr = [dbEventListRow objectAtIndex:2];
            
            int64_t eventTimeStamp = [eventTimeIntervalStr longLongValue];
            NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:eventTimeStamp];
            
            NSArray* __autoreleasing eventParamList = nil;
            if (![_db executeSQL:[NSString stringWithFormat:@"SELECT name, value FROM event WHERE eventid = %qi;",eventId] withResultsColumCount:2 producingResults:&eventParamList]) {
                return nil;
            }
            
            QuantcastEvent* e = [QuantcastEvent dataBaseEvent:sessionId timestamp:timestamp withParameterList:eventParamList];
            
            [eventList addObject:e];
        }
        
        if (inDoDeleteDBEvents) {
            [self deleteEvents:tempTableName];
        }
    }
    
    [_db endDatabaseTransaction];
    
    return eventList;
}

-(NSUInteger)eventCount {
    return (NSUInteger)[_db rowCountForTable:@"events"];
}

-(void)trimEventsDatabaseBy:(NSUInteger)inEventsToDelete {
    if ( _isDataDumpInprogress ) {
        return;
    }
    
    _isDataDumpInprogress = YES;
    
    [_db beginDatabaseTransaction];
    
    NSUInteger curEventCount = [self eventCount];
    
    NSUInteger deleteEventCount = MIN(inEventsToDelete, curEventCount);
    
    QUANTCAST_LOG(@"Deleting %lu events from the event database.", (unsigned long)deleteEventCount);

    // first we move up to event records into a working table
    NSString* tempTableName = [self makeTempTableWithEvents:deleteEventCount];

    if( nil != tempTableName){
        [self deleteEvents:tempTableName];
    }

    [_db endDatabaseTransaction];
    
    _isDataDumpInprogress = NO;

}

-(NSString*)makeTempTableWithEvents:(NSUInteger)eventcount{
    NSString* tempTableName = [NSString stringWithFormat:@"events_%qi", (int64_t) floor([[NSDate date] timeIntervalSince1970]*1000) ];
    
    NSString* createTempTableSQL = [NSString stringWithFormat:@"CREATE TEMPORARY TABLE %@ ( id integer primary key, sessionId varchar not null, timestamp integer not null );", tempTableName];
    
    [_db executeSQL:createTempTableSQL];
    
    
    NSString* moveToTmpSQL = [NSString stringWithFormat:@"INSERT INTO %@ ( id, sessionId, timestamp ) SELECT id, sessionId, timestamp FROM events ORDER BY id LIMIT %lu;", tempTableName, (unsigned long)eventcount ];
    
    if ( ![_db executeSQL:moveToTmpSQL] ) {
        QUANTCAST_LOG(@"Could not move events to dump to temporary table named %@", tempTableName );
        return nil;
    }
    return tempTableName;
}

-(void)deleteEvents:(NSString*)tempTableName{
    NSString* deleteEventsSQL = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN ( SELECT id FROM %@ );", tempTableName];
    NSString* deleteEventRecordsSQL = [NSString stringWithFormat:@"DELETE FROM event WHERE eventid IN ( SELECT id FROM %@ temp );", tempTableName];
    
    [_db executeSQL:deleteEventsSQL];
    [_db executeSQL:deleteEventRecordsSQL];
    
    // reset autoincrement in table?
    
    if ( [self eventCount] == 0 ) {
        
        [_db setAutoIncrementTo:0 forTable:@"events"];
    }
}

#pragma mark - Data File Management

-(NSString*)dumpDataManagerToFileWithUploadID:(NSString*)inUploadID withPolicy:(QuantcastPolicy*)inPolicy {
    
    // first check to see if policy is ready
    if (!inPolicy.hasPolicyBeenLoaded) {
        return nil;
    }
    
    NSString* genDirPath = [QuantcastUtils quantcastDataGeneratingDirectoryPath];
    
    NSString* filename = [inUploadID stringByAppendingPathExtension:@"json"];
    NSString* creationFilepath = [genDirPath stringByAppendingPathComponent:filename];
    NSString* finalFilepath =[[QuantcastUtils quantcastDataReadyToUploadDirectoryPath] stringByAppendingPathComponent:filename];
    
    // first check if file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:creationFilepath]) {
       QUANTCAST_LOG(@"Upload file '%@' already exists at path '%@'. Deleting ...", filename, creationFilepath );
        [fileManager removeItemAtPath:creationFilepath error:nil];
    }
    if ([fileManager fileExistsAtPath:finalFilepath]) {
       QUANTCAST_LOG(@"Upload file '%@' already exists at path '%@'. Deleting ...", filename, finalFilepath );
        [fileManager removeItemAtPath:finalFilepath error:nil];
    }
    
    // generate JSON data
    NSData *fileJSONData = [self genJSONDataWithDeletingDatabase:YES uploadID:inUploadID withPolicy:inPolicy];
    
    if( nil == fileJSONData){
        QUANTCAST_LOG(@"Event data is empty. Abort uploading." );
        return nil;
    }
    
    if ( ![fileManager createFileAtPath:creationFilepath contents:fileJSONData attributes:nil] ) {
        NSString* fileJSONStr = [[NSString alloc] initWithData:fileJSONData encoding:NSUTF8StringEncoding];
       QUANTCAST_LOG(@"Could not create JSON file at path '%@' with contents = %@", creationFilepath, fileJSONStr );
        return nil;
    }
    
    // file has been created. Now move it to it's ready loacation.
    
    NSError* __autoreleasing error = nil;
    if ( ![fileManager moveItemAtPath:creationFilepath toPath:finalFilepath error:&error] ) {
       QUANTCAST_LOG(@"Could note move file '%@' to location '%@'. Error = %@", creationFilepath, finalFilepath, [error localizedDescription] );
        return nil;
    }
    
    return finalFilepath;
}


#pragma mark - JSON conversion
-(NSData*)genJSONDataWithDeletingDatabase:(BOOL)inDoDeleteDB uploadID:(NSString*)inUploadID withPolicy:(QuantcastPolicy*)inPolicy{
    if (nil == _db) {
        QUANTCAST_LOG(@"Could not dump events to JSON because there is no database connection");
        return nil;
    }
    
    NSMutableDictionary* jsonDict = [NSMutableDictionary dictionaryWithCapacity:5];
    [jsonDict setObject:inUploadID forKey:@"uplid"];
    [jsonDict setObject:QCMEASUREMENT_API_IDENTIFIER forKey:@"qcv"];
    if(nil != inPolicy.apiKey){
        [jsonDict setObject:inPolicy.apiKey forKey:QCPARAMATER_APIKEY];
    }
    if(nil != inPolicy.networkCode){
        [jsonDict setObject:inPolicy.networkCode forKey:QCPARAMETER_NETWORKPCODE];
    }
    
    NSData *jsonData = nil;
    NSArray* eventList = [self recordedEventsWithDeleteDBEvents:inDoDeleteDB];
    if(eventList.count > 0){
        NSMutableArray* jsonArray = [NSMutableArray arrayWithCapacity:eventList.count];
        for ( QuantcastEvent* e in eventList ) {
            [jsonArray addObject:[e JSONDictEnforcingPolicy:inPolicy]];
        }
        [jsonDict setObject:jsonArray forKey:@"events"];
        
        NSError *writeError = nil;
        // try to use NSJSONSerialization first. check to see if class is available (iOS 5 or later)
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        
        if (nil != jsonClass) {
            jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&writeError];
        }
    #if QCMEASUREMENT_ENABLE_JSONKIT
        else if (nil != NSClassFromString(@"JSONDecoder")) {
            // try with JSONKit
            jsonData = [jsonDict JSONDataWithOptions:JKSerializeOptionEscapeForwardSlashes error:&writeError];
        }
    #endif
        else {
            QUANTCAST_ERROR(@"There is no available JSON encoder to user. Please enable JSONKit in your project!");
        }
        
        if(nil != writeError){
           QUANTCAST_ERROR(@"Could not write JSON data. Error: %@",writeError);
        }
    }
    return jsonData;
}

-(QuantcastUploadManager*)uploadManager{
    return _uploadManager;
}

#pragma mark - Opt-Out Handleing
@synthesize isOptOut=_isOptOut;


-(void)setIsOptOut:(BOOL)inIsOptOut {
    BOOL originalValue = _isOptOut;
    
    _isOptOut = inIsOptOut;
    
    if ( originalValue != inIsOptOut ) {
        if ( inIsOptOut ) {
            // stop all uploading
            _uploadManager = nil;

            // make sure database connection is closed
            [_db closeDatabaseConnection];
            _db = nil;
            
            // get rid of all Quantcast data on device
            [QuantcastUtils emptyAllQuantcastCaches];
        }
        else {
            [self setUpEventDatabaseConnection];
        }
    }
}

@end
