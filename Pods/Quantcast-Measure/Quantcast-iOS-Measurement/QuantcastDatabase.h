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


#import <Foundation/Foundation.h>
#import <sqlite3.h>

/*!
 @class QuantcastDatabase
 @internal
 */
@interface QuantcastDatabase : NSObject

+(QuantcastDatabase*)databaseWithFilePath:(NSString*)inFilePath;


-(id)initWithFilePath:(NSString*)inFilePath;

-(BOOL)beginDatabaseTransaction;
-(BOOL)rollbackDatabaseTransaction;
-(BOOL)endDatabaseTransaction;

/*!
 @internal
 @method executeSQL:
 @abstract Executes the passed SQL query on the database. This form of the method should be used for queries that expect no results.
 @param inSQL the SQL query
 @result a boolean indicating whether the query suceeded or not.
 */
-(BOOL)executeSQL:(NSString*)inSQL;

/*!
 @internal
 @method executeSQL:withResultsColumCount:producingResults:
 @abstract Executes the passed SQL query on the database. This form of the method should be used for queries that expect results.
 @param inSQL the SQL query
 @param inResultsColumnCount the number of results columns that should be expected from the query
 @param outResultsArray a pointer to a NSArray* variable into which the results array will be placed. The NSArray* pointed to should be nil when passed in. It will be nil when th function returns if the query was not successfully executed. If the query was successful but had no results, the NSArray* will be set to an empty array.
 @result a boolean indicating whether the query suceeded or not.
 */
-(BOOL)executeSQL:(NSString*)inSQL withResultsColumCount:(NSUInteger)inResultsColumnCount producingResults:(NSArray*__autoreleasing*)outResultsArray;

-(int64_t)getLastInsertRowId;

-(BOOL)setAutoIncrementTo:(int64_t)inAutoIncrementValue forTable:(NSString*)inTableName;

-(int64_t)rowCountForTable:(NSString*)inTableName;

-(void)closeDatabaseConnection;

#pragma mark - Prepared Queries

-(void)prepareQuery:(NSString*)inQueryToPreprare withKey:(NSString*)inQueryKey;

/*!
 @internal
 @method executePreparedQuery:bindingData:
 @abstract executes a prepared query binding the passed data for inserts. 
 */
-(BOOL)executePreparedQuery:(NSString*)inQueryKey bindingInsertData:(NSArray*)inArrayOfStringsOrNil;
-(void)clearPreparedQuery:(NSString*)inQueryKey;
-(void)clearAllPreparedQueries;

@end
