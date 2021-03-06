/*
 * Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AWSLambda.h"

#import "AWSNetworking.h"
#import "AWSCategory.h"
#import "AWSSignature.h"
#import "AWSService.h"
#import "AWSNetworking.h"
#import "AWSURLRequestSerialization.h"
#import "AWSURLResponseSerialization.h"
#import "AWSURLRequestRetryHandler.h"
#import "AWSSynchronizedMutableDictionary.h"
#import "AWSLambdaResources.h"

NSString *const AWSLambdaDefinitionFileName = @"lambda-2015-03-31";

@interface AWSLambdaResponseSerializer : AWSJSONResponseSerializer

@end

@implementation AWSLambdaResponseSerializer

#pragma mark - Service errors

static NSDictionary *errorCodeDictionary = nil;
+ (void)initialize {
    errorCodeDictionary = @{
                            @"IncompleteSignature" : @(AWSLambdaErrorIncompleteSignature),
                            @"InvalidClientTokenId" : @(AWSLambdaErrorInvalidClientTokenId),
                            @"MissingAuthenticationToken" : @(AWSLambdaErrorMissingAuthenticationToken),
                            @"CodeStorageExceededException" : @(AWSLambdaErrorCodeStorageExceeded),
                            @"InvalidParameterValueException" : @(AWSLambdaErrorInvalidParameterValue),
                            @"InvalidRequestContentException" : @(AWSLambdaErrorInvalidRequestContent),
                            @"PolicyLengthExceededException" : @(AWSLambdaErrorPolicyLengthExceeded),
                            @"RequestTooLargeException" : @(AWSLambdaErrorRequestTooLarge),
                            @"ResourceConflictException" : @(AWSLambdaErrorResourceConflict),
                            @"ResourceNotFoundException" : @(AWSLambdaErrorResourceNotFound),
                            @"ServiceException" : @(AWSLambdaErrorService),
                            @"TooManyRequestsException" : @(AWSLambdaErrorTooManyRequests),
                            @"UnsupportedMediaTypeException" : @(AWSLambdaErrorUnsupportedMediaType),
                            };
}

#pragma mark -

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                originalRequest:(NSURLRequest *)originalRequest
                 currentRequest:(NSURLRequest *)currentRequest
                           data:(id)data
                          error:(NSError *__autoreleasing *)error {
    id responseObject = [super responseObjectForResponse:response
                                         originalRequest:originalRequest
                                          currentRequest:currentRequest
                                                    data:data
                                                   error:error];
    if (*error) {
        NSMutableDictionary *richUserInfo = [NSMutableDictionary dictionaryWithDictionary:(*error).userInfo];
        [richUserInfo setObject:@"responseStatusCode" forKey:@([response statusCode])];
        [richUserInfo setObject:@"responseHeaders" forKey:[response allHeaderFields]];
        [richUserInfo setObject:@"responseDataSize" forKey:@(data?[data length]:0)];
        *error = [NSError errorWithDomain:(*error).domain
                                     code:(*error).code
                                 userInfo:richUserInfo];
    }

    if (!*error && [responseObject isKindOfClass:[NSDictionary class]]) {
        NSString *errorTypeHeader = [[[[response allHeaderFields] objectForKey:@"x-amzn-ErrorType"] componentsSeparatedByString:@":"] firstObject];

        //server may also return error message in the body, need to catch it.
        if (errorTypeHeader == nil) {
            errorTypeHeader = [responseObject objectForKey:@"__type"];
        }

        if (errorCodeDictionary[[[errorTypeHeader componentsSeparatedByString:@"#"] lastObject]]) {
            if (error) {
                NSMutableDictionary *userInfo = [@{
                                                   NSLocalizedFailureReasonErrorKey : errorTypeHeader,
                                                   @"responseStatusCode" : @([response statusCode]),
                                                   @"responseHeaders" : [response allHeaderFields],
                                                   @"responseDataSize" : @(data?[data length]:0),
                                                   } mutableCopy];
                [userInfo addEntriesFromDictionary:responseObject];
                *error = [NSError errorWithDomain:AWSLambdaErrorDomain
                                             code:[[errorCodeDictionary objectForKey:[[errorTypeHeader componentsSeparatedByString:@"#"] lastObject]] integerValue]
                                         userInfo:userInfo];
            }
            return responseObject;
        } else if ([[errorTypeHeader componentsSeparatedByString:@"#"] lastObject]) {
            if (error) {
                NSMutableDictionary *userInfo = [@{
                                                   NSLocalizedFailureReasonErrorKey : errorTypeHeader,
                                                   @"responseStatusCode" : @([response statusCode]),
                                                   @"responseHeaders" : [response allHeaderFields],
                                                   @"responseDataSize" : @(data?[data length]:0),
                                                   } mutableCopy];
                [userInfo addEntriesFromDictionary:responseObject];
                *error = [NSError errorWithDomain:AWSLambdaErrorDomain
                                             code:AWSLambdaErrorUnknown
                                         userInfo:userInfo];
            }
            return responseObject;
        } else if (response.statusCode/100 != 2) {
            //should be an error if not a 2xx response.
            if (error) {
                *error = [NSError errorWithDomain:AWSLambdaErrorDomain
                                             code:AWSLambdaErrorUnknown
                                         userInfo:responseObject];
            }
            return responseObject;
        }


        if (self.outputClass) {
            responseObject = [AWSMTLJSONAdapter modelOfClass:self.outputClass
                                          fromJSONDictionary:responseObject
                                                       error:error];
        }
    }

    if (responseObject == nil) {
        return @{@"responseStatusCode" : @([response statusCode]),
                 @"responseHeaders" : [response allHeaderFields],
                 @"responseDataSize" : @(data?[data length]:0),
                 };
    }

    return responseObject;
}

@end

@interface AWSLambdaRequestRetryHandler : AWSURLRequestRetryHandler

@end

@implementation AWSLambdaRequestRetryHandler

- (AWSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                             response:(NSHTTPURLResponse *)response
                                 data:(NSData *)data
                                error:(NSError *)error {
    AWSNetworkingRetryType retryType = [super shouldRetry:currentRetryCount
                                                 response:response
                                                     data:data
                                                    error:error];
    if(retryType == AWSNetworkingRetryTypeShouldNotRetry
       && [error.domain isEqualToString:AWSLambdaErrorDomain]
       && currentRetryCount < self.maxRetryCount) {
        switch (error.code) {
            case AWSLambdaErrorIncompleteSignature:
            case AWSLambdaErrorInvalidClientTokenId:
            case AWSLambdaErrorMissingAuthenticationToken:
                retryType = AWSNetworkingRetryTypeShouldRefreshCredentialsAndRetry;
                break;

            default:
                break;
        }
    }

    return retryType;
}

@end

@interface AWSRequest()

@property (nonatomic, strong) AWSNetworkingRequest *internalRequest;

@end

@interface AWSLambda()

@property (nonatomic, strong) AWSNetworking *networking;
@property (nonatomic, strong) AWSServiceConfiguration *configuration;

@end

@interface AWSServiceConfiguration()

@property (nonatomic, strong) AWSEndpoint *endpoint;

@end

@implementation AWSLambda

static AWSSynchronizedMutableDictionary *_serviceClients = nil;

+ (instancetype)defaultLambda {
    if (![AWSServiceManager defaultServiceManager].defaultServiceConfiguration) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"`defaultServiceConfiguration` is `nil`. You need to set it before using this method."
                                     userInfo:nil];
    }

    static AWSLambda *_defaultLambda = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _defaultLambda = [[AWSLambda alloc] initWithConfiguration:AWSServiceManager.defaultServiceManager.defaultServiceConfiguration];
#pragma clang diagnostic pop
    });

    return _defaultLambda;
}

+ (void)registerLambdaWithConfiguration:(AWSServiceConfiguration *)configuration forKey:(NSString *)key {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _serviceClients = [AWSSynchronizedMutableDictionary new];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_serviceClients setObject:[[AWSLambda alloc] initWithConfiguration:configuration]
                        forKey:key];
#pragma clang diagnostic pop
}

+ (instancetype)LambdaForKey:(NSString *)key {
    return [_serviceClients objectForKey:key];
}

+ (void)removeLambdaForKey:(NSString *)key {
    [_serviceClients removeObjectForKey:key];
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"`- init` is not a valid initializer. Use `+ defaultLambda` or `+ LambdaForKey:` instead."
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithConfiguration:(AWSServiceConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = [configuration copy];

        _configuration.endpoint = [[AWSEndpoint alloc] initWithRegion:_configuration.regionType
                                                              service:AWSServiceLambda
                                                         useUnsafeURL:NO];

        AWSSignatureV4Signer *signer = [[AWSSignatureV4Signer alloc] initWithCredentialsProvider:_configuration.credentialsProvider
                                                                                  endpoint:_configuration.endpoint];
        AWSNetworkingRequestInterceptor *baseInterceptor = [[AWSNetworkingRequestInterceptor alloc] initWithUserAgent:_configuration.userAgent];
        _configuration.requestInterceptors = @[baseInterceptor, signer];

        _configuration.baseURL = _configuration.endpoint.URL;
        _configuration.requestSerializer = [AWSJSONRequestSerializer new];
        _configuration.retryHandler = [[AWSLambdaRequestRetryHandler alloc] initWithMaximumRetryCount:_configuration.maxRetryCount];
        _configuration.headers = @{@"Content-Type" : @"application/x-amz-json-1.0"};

        _networking = [[AWSNetworking alloc] initWithConfiguration:_configuration];
    }

    return self;
}

- (AWSTask *)invokeRequest:(AWSRequest *)request
               HTTPMethod:(AWSHTTPMethod)HTTPMethod
                URLString:(NSString *) URLString
             targetPrefix:(NSString *)targetPrefix
            operationName:(NSString *)operationName
              outputClass:(Class)outputClass {
    
    @autoreleasepool {
        if (!request) {
            request = [AWSRequest new];
        }
        
        AWSNetworkingRequest *networkingRequest = request.internalRequest;
        if (request) {
            networkingRequest.parameters = [[AWSMTLJSONAdapter JSONDictionaryFromModel:request] aws_removeNullValues];
        } else {
            networkingRequest.parameters = @{};
        }
        NSMutableDictionary *headers = [NSMutableDictionary new];
        
        networkingRequest.headers = headers;
        networkingRequest.HTTPMethod = HTTPMethod;
        networkingRequest.requestSerializer = [[AWSJSONRequestSerializer alloc] initWithJSONDefinition:[[AWSLambdaResources sharedInstance] JSONObject]
                                                                                            actionName:operationName];
        networkingRequest.responseSerializer = [[AWSLambdaResponseSerializer alloc] initWithJSONDefinition:[[AWSLambdaResources sharedInstance] JSONObject]
                                                                                                actionName:operationName
                                                                                               outputClass:outputClass];
        return [self.networking sendRequest:networkingRequest];
    }
}

#pragma mark - Service method


- (AWSTask *)addPermission:(AWSLambdaAddPermissionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/functions/{FunctionName}/policy"
                  targetPrefix:@""
                 operationName:@"AddPermission"
                   outputClass:[AWSLambdaAddPermissionResponse class]];
}

- (AWSTask *)createAlias:(AWSLambdaCreateAliasRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/functions/{FunctionName}/aliases"
                  targetPrefix:@""
                 operationName:@"CreateAlias"
                   outputClass:[AWSLambdaAliasConfiguration class]];
}

- (AWSTask *)createEventSourceMapping:(AWSLambdaCreateEventSourceMappingRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/event-source-mappings/"
                  targetPrefix:@""
                 operationName:@"CreateEventSourceMapping"
                   outputClass:[AWSLambdaEventSourceMappingConfiguration class]];
}

- (AWSTask *)createFunction:(AWSLambdaCreateFunctionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/functions"
                  targetPrefix:@""
                 operationName:@"CreateFunction"
                   outputClass:[AWSLambdaFunctionConfiguration class]];
}

- (AWSTask *)deleteAlias:(AWSLambdaDeleteAliasRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodDELETE
                     URLString:@"/2015-03-31/functions/{FunctionName}/aliases/{Name}"
                  targetPrefix:@""
                 operationName:@"DeleteAlias"
                   outputClass:nil];
}

- (AWSTask *)deleteEventSourceMapping:(AWSLambdaDeleteEventSourceMappingRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodDELETE
                     URLString:@"/2015-03-31/event-source-mappings/{UUID}"
                  targetPrefix:@""
                 operationName:@"DeleteEventSourceMapping"
                   outputClass:[AWSLambdaEventSourceMappingConfiguration class]];
}

- (AWSTask *)deleteFunction:(AWSLambdaDeleteFunctionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodDELETE
                     URLString:@"/2015-03-31/functions/{FunctionName}"
                  targetPrefix:@""
                 operationName:@"DeleteFunction"
                   outputClass:nil];
}

- (AWSTask *)getAlias:(AWSLambdaGetAliasRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}/aliases/{Name}"
                  targetPrefix:@""
                 operationName:@"GetAlias"
                   outputClass:[AWSLambdaAliasConfiguration class]];
}

- (AWSTask *)getEventSourceMapping:(AWSLambdaGetEventSourceMappingRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/event-source-mappings/{UUID}"
                  targetPrefix:@""
                 operationName:@"GetEventSourceMapping"
                   outputClass:[AWSLambdaEventSourceMappingConfiguration class]];
}

- (AWSTask *)getFunction:(AWSLambdaGetFunctionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}"
                  targetPrefix:@""
                 operationName:@"GetFunction"
                   outputClass:[AWSLambdaGetFunctionResponse class]];
}

- (AWSTask *)getFunctionConfiguration:(AWSLambdaGetFunctionConfigurationRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}/configuration"
                  targetPrefix:@""
                 operationName:@"GetFunctionConfiguration"
                   outputClass:[AWSLambdaFunctionConfiguration class]];
}

- (AWSTask *)getPolicy:(AWSLambdaGetPolicyRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}/policy"
                  targetPrefix:@""
                 operationName:@"GetPolicy"
                   outputClass:[AWSLambdaGetPolicyResponse class]];
}

- (AWSTask *)invoke:(AWSLambdaInvocationRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/functions/{FunctionName}/invocations"
                  targetPrefix:@""
                 operationName:@"Invoke"
                   outputClass:[AWSLambdaInvocationResponse class]];
}

- (AWSTask *)invokeAsync:(AWSLambdaInvokeAsyncRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2014-11-13/functions/{FunctionName}/invoke-async/"
                  targetPrefix:@""
                 operationName:@"InvokeAsync"
                   outputClass:[AWSLambdaInvokeAsyncResponse class]];
}

- (AWSTask *)listAliases:(AWSLambdaListAliasesRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}/aliases"
                  targetPrefix:@""
                 operationName:@"ListAliases"
                   outputClass:[AWSLambdaListAliasesResponse class]];
}

- (AWSTask *)listEventSourceMappings:(AWSLambdaListEventSourceMappingsRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/event-source-mappings/"
                  targetPrefix:@""
                 operationName:@"ListEventSourceMappings"
                   outputClass:[AWSLambdaListEventSourceMappingsResponse class]];
}

- (AWSTask *)listFunctions:(AWSLambdaListFunctionsRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/"
                  targetPrefix:@""
                 operationName:@"ListFunctions"
                   outputClass:[AWSLambdaListFunctionsResponse class]];
}

- (AWSTask *)listVersionsByFunction:(AWSLambdaListVersionsByFunctionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodGET
                     URLString:@"/2015-03-31/functions/{FunctionName}/versions"
                  targetPrefix:@""
                 operationName:@"ListVersionsByFunction"
                   outputClass:[AWSLambdaListVersionsByFunctionResponse class]];
}

- (AWSTask *)publishVersion:(AWSLambdaPublishVersionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/2015-03-31/functions/{FunctionName}/versions"
                  targetPrefix:@""
                 operationName:@"PublishVersion"
                   outputClass:[AWSLambdaFunctionConfiguration class]];
}

- (AWSTask *)removePermission:(AWSLambdaRemovePermissionRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodDELETE
                     URLString:@"/2015-03-31/functions/{FunctionName}/policy/{StatementId}"
                  targetPrefix:@""
                 operationName:@"RemovePermission"
                   outputClass:nil];
}

- (AWSTask *)updateAlias:(AWSLambdaUpdateAliasRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPUT
                     URLString:@"/2015-03-31/functions/{FunctionName}/aliases/{Name}"
                  targetPrefix:@""
                 operationName:@"UpdateAlias"
                   outputClass:[AWSLambdaAliasConfiguration class]];
}

- (AWSTask *)updateEventSourceMapping:(AWSLambdaUpdateEventSourceMappingRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPUT
                     URLString:@"/2015-03-31/event-source-mappings/{UUID}"
                  targetPrefix:@""
                 operationName:@"UpdateEventSourceMapping"
                   outputClass:[AWSLambdaEventSourceMappingConfiguration class]];
}

- (AWSTask *)updateFunctionCode:(AWSLambdaUpdateFunctionCodeRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPUT
                     URLString:@"/2015-03-31/functions/{FunctionName}/code"
                  targetPrefix:@""
                 operationName:@"UpdateFunctionCode"
                   outputClass:[AWSLambdaFunctionConfiguration class]];
}

- (AWSTask *)updateFunctionConfiguration:(AWSLambdaUpdateFunctionConfigurationRequest *)request {
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPUT
                     URLString:@"/2015-03-31/functions/{FunctionName}/configuration"
                  targetPrefix:@""
                 operationName:@"UpdateFunctionConfiguration"
                   outputClass:[AWSLambdaFunctionConfiguration class]];
}

@end
