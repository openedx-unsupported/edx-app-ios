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

#import "QuantcastDatabase.h"
#import "QuantcastUtils.h"

@interface QuantcastDatabase (){
    
    NSString* _databaseFilePath;
    sqlite3* _databaseConnection;
    
    NSMutableDictionary* _preparedStatements;
    
}
@property (readonly)sqlite3* databaseConnection;
-(void)clearStatementInDataObject:(NSData*)inStatementDataObj;

@end

@implementation QuantcastDatabase

+(QuantcastDatabase*)databaseWithFilePath:(NSString*)inFilePath {
    
    return [[QuantcastDatabase alloc] initWithFilePath:inFilePath];
}


-(id)initWithFilePath:(NSString*)inFilePath {
    self = [super init];
    
    if ( self ) {
        _databaseFilePath = inFilePath;
        _preparedStatements = [[NSMutableDictionary alloc] initWithCapacity:1];
        
        if ( !sqlite3_threadsafe() ) {
            QUANTCAST_WARN(@"This app is using a version of SQLite that is not thread safe. Strange things might happen.");
        }
    }
    
    return self;
}

-(void)dealloc {
    
    
    [self closeDatabaseConnection];
    
}

-(NSString*)databaseFilePath {
    return _databaseFilePath;
}

-(sqlite3*)databaseConnection {
    
    if (NULL == _databaseConnection) {
        const char* dbpath = [self.databaseFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &_databaseConnection) != SQLITE_OK) {
           QUANTCAST_LOG(@"Could not open sqllite3 database with path = %@", _databaseFilePath );
            return NULL;
        }
    }
    
    return _databaseConnection;
}
-(void)closeDatabaseConnection {
    if ( NULL != _databaseConnection ) {
        [self clearAllPreparedQueries];
        
        sqlite3_close(_databaseConnection);
        
        _databaseConnection = NULL;
    }
}


-(BOOL)beginDatabaseTransaction {
    return [self executeSQL:@"BEGIN TRANSACTION;"];
}

-(BOOL)rollbackDatabaseTransaction {
    return [self executeSQL:@"ROLLBACK;"];
}


-(BOOL)endDatabaseTransaction {
    return [self executeSQL:@"COMMIT;"];
}

-(BOOL)executeSQL:(NSString*)inSQL {
    if ( NULL != self.databaseConnection ) {
        sqlite3_stmt    *statement = NULL;
        
        const char *sql_stmt = [inSQL UTF8String];
        
        if ( sqlite3_prepare_v2(self.databaseConnection, sql_stmt, -1, &statement, NULL) != SQLITE_OK ) {
           QUANTCAST_LOG(@"Could not prepare sqllite3 statment with sql = %@", inSQL );
            return NO;
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
           QUANTCAST_LOG(@"Could not step sqllite3 statment with sql = %@", inSQL );
            return NO;
        }
        
        sqlite3_finalize(statement);
    }
    
    return YES;
}

-(BOOL)executeSQL:(NSString*)inSQL withResultsColumCount:(NSUInteger)inResultsColumnCount producingResults:(NSArray*__autoreleasing*)outResultsArray {
    
    NSMutableArray* resultRows = nil;

    if ( NULL != self.databaseConnection ) {
        
        sqlite3_stmt    *statement = NULL;
        
        const char *sql_stmt = [inSQL UTF8String];
        
        if ( sqlite3_prepare_v2(self.databaseConnection, sql_stmt, -1, &statement, NULL) == SQLITE_OK ) {
            
            resultRows = [NSMutableArray arrayWithCapacity:1];
            
            while (sqlite3_step(statement) == SQLITE_ROW ) {
                
                NSMutableArray* rowValues = [NSMutableArray arrayWithCapacity:inResultsColumnCount];
                
                for (NSUInteger i = 0; i < inResultsColumnCount; ++i ) {
                    const char* dbText = (const char *)sqlite3_column_text(statement, (int)i);
                    if(NULL != dbText){
                        NSString* columnValue = [[NSString alloc] initWithUTF8String:dbText ];
                        
                        if( nil != columnValue ){
                            [rowValues addObject:columnValue];
                        }
                        else {
                            [rowValues addObject:@"_badVal"];
                        }
                    }
                    else {
                        [rowValues addObject:@"_badVal"];
                    }
                }
                
                [resultRows addObject:rowValues];
            }
            
            sqlite3_finalize(statement);
        }
        else {
           QUANTCAST_LOG(@"Could not prepare sqllite3 statment with sql = %@", inSQL );
            return NO;
        }
    }
    
    (*outResultsArray) = resultRows;
    
    return YES;
}

-(int64_t)getLastInsertRowId {
    int64_t lastRow = NSNotFound;
    if(NULL != self.databaseConnection){
        lastRow = sqlite3_last_insert_rowid( _databaseConnection );
    }
    return lastRow;
}

-(BOOL)setAutoIncrementTo:(int64_t)inAutoIncrementValue forTable:(NSString*)inTableName {
    NSString* sql = [NSString stringWithFormat:@"UPDATE sqlite_sequence SET seq = %qi WHERE name = '%@';",inAutoIncrementValue,inTableName];
    
    return [self executeSQL:sql];
}

-(int64_t)rowCountForTable:(NSString*)inTableName {
    
    NSString* sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@;",inTableName];
    
    NSArray* __autoreleasing results = nil;
    
    if ([self executeSQL:sql withResultsColumCount:1 producingResults:&results]) {
        if ( 1 == [results count] ) {
            NSArray* rowResults = [results objectAtIndex:0];
            
            if ( 1 == [rowResults count] ) {
                NSNumber* countValue = [rowResults objectAtIndex:0];
                
                return [countValue longLongValue];
            }
        }
        
    }
    
    return 0;
}
#pragma mark - Prepared Queries

-(void)prepareQuery:(NSString*)inQueryToPreprare withKey:(NSString*)inQueryKey {
    
    if( NULL != self.databaseConnection){
        sqlite3_stmt* statement = NULL;
        
        const char *sql_string = [inQueryToPreprare UTF8String];
        
        int error = sqlite3_prepare_v2(_databaseConnection, sql_string, -1, &statement, NULL);
        if ( error == SQLITE_OK ) {
            NSData* statementObj = [NSData dataWithBytes:&statement length:sizeof(statement)];
            [_preparedStatements setObject:statementObj forKey:inQueryKey];
        }
        else {
           QUANTCAST_LOG(@"Could not prepare sqllite3 statment with sql = %@ for query key = %@", inQueryToPreprare, inQueryKey );
        }
    }
}

-(BOOL)executePreparedQuery:(NSString*)inQueryKey bindingInsertData:(NSArray*)inArrayOfStrings {
    
    NSData* statementObj = [_preparedStatements objectForKey:inQueryKey];
    
    if (nil == statementObj) {
       QUANTCAST_LOG(@"Could find prepared sqllite3 statment with key = %@", inQueryKey );
        return NO;
    }
    
    sqlite3_stmt* statement = NULL;
    [statementObj getBytes:&statement length:sizeof(statement)];
    
    if ( inArrayOfStrings.count > 0 ) {
        
        for (NSUInteger i = 0; i < [inArrayOfStrings count]; ++i ) {
            
            NSString* value = [inArrayOfStrings objectAtIndex:i];
            const char *valueStr = [value UTF8String];
            sqlite3_bind_text(statement, (int)i+1, valueStr, -1, SQLITE_TRANSIENT);
            
        }
    }
    
    if (sqlite3_step(statement) != SQLITE_DONE) {
       QUANTCAST_LOG(@"Could not step prepared sqllite3 statment with query key = %@", inQueryKey );
        return NO;
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    return YES;
}

-(void)clearPreparedQuery:(NSString*)inQueryKey {
    
    NSData* statementObj = [_preparedStatements objectForKey:inQueryKey];
    if (nil == statementObj) {
       QUANTCAST_LOG(@"Could find prepared sqllite3 statment with key = %@. As a result, can not clear the statement.", inQueryKey );
    }
    
    [self clearStatementInDataObject:statementObj];
    [_preparedStatements removeObjectForKey:inQueryKey];
    
}

-(void)clearAllPreparedQueries {
    
    NSDictionary* oldList = _preparedStatements;
    _preparedStatements = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    for ( NSString* key in oldList ) {
        NSData* statementObj = [oldList objectForKey:key];
        if (nil == statementObj) {
           QUANTCAST_LOG(@"Could find prepared sqllite3 statment with key = %@. As a result, can not clear the statement.", key );
        }
        [self clearStatementInDataObject:statementObj];
    }
    
}

-(void)clearStatementInDataObject:(NSData*)inStatementDataObj {
    
    sqlite3_stmt* statement = NULL;
    [inStatementDataObj getBytes:&statement length:sizeof(statement)];
    sqlite3_finalize( statement );
    
}

#pragma mark - Debugging
- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastDatabase %p: path = %@>", self, _databaseFilePath ];
}

@end
