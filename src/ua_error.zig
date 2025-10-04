const std = @import("std");
const c = @import("c.zig");

pub const StatusCode = u32;

/// Helper function to convert status codes from c.zig to StatusCode (u32)
/// This reinterprets the bits to handle values with the sign bit set
inline fn toStatusCode(value: anytype) StatusCode {
    return @as(StatusCode, @intCast(value));
}

// Status code constants from imported c.zig
pub const GOOD: StatusCode = toStatusCode(c.UA_STATUSCODE_GOOD);
pub const UNCERTAIN: StatusCode = toStatusCode(c.UA_STATUSCODE_UNCERTAIN);
pub const BAD: StatusCode = toStatusCode(c.UA_STATUSCODE_BAD);

pub const OpcUaError = error{
    // Uncertain status codes
    Uncertain,
    UncertainReferenceNotDeleted,
    UncertainNotAllNodesAvailable,
    UncertainReferenceOutOfServer,
    UncertainNoCommunicationLastUsableValue,
    UncertainLastUsableValue,
    UncertainSubstituteValue,
    UncertainInitialValue,
    UncertainSensorNotAccurate,
    UncertainEngineeringUnitsExceeded,
    UncertainSubnormal,
    UncertainDataSubnormal,
    UncertainDominantValueChanged,
    UncertainDependentValueChanged,
    UncertainTransducerInManual,
    UncertainSimulatedValue,
    UncertainSensorCalibration,
    UncertainConfigurationError,

    // Bad status codes - General
    BadUnexpectedError,
    BadInternalError,
    BadOutOfMemory,
    BadResourceUnavailable,
    BadCommunicationError,
    BadEncodingError,
    BadDecodingError,
    BadEncodingLimitsExceeded,
    BadRequestTooLarge,
    BadResponseTooLarge,
    BadUnknownResponse,
    BadTimeout,
    BadServiceUnsupported,
    BadShutdown,
    BadServerNotConnected,
    BadServerHalted,
    BadNothingToDo,
    BadTooManyOperations,
    BadTooManyMonitoredItems,
    BadDataTypeIdUnknown,

    // Certificate related
    BadCertificateInvalid,
    BadSecurityChecksFailed,
    BadCertificatePolicyCheckFailed,
    BadCertificateTimeInvalid,
    BadCertificateIssuerTimeInvalid,
    BadCertificateHostNameInvalid,
    BadCertificateUriInvalid,
    BadCertificateUseNotAllowed,
    BadCertificateIssuerUseNotAllowed,
    BadCertificateUntrusted,
    BadCertificateRevocationUnknown,
    BadCertificateIssuerRevocationUnknown,
    BadCertificateRevoked,
    BadCertificateIssuerRevoked,
    BadCertificateChainIncomplete,

    // User/Identity related
    BadUserAccessDenied,
    BadIdentityTokenInvalid,
    BadIdentityTokenRejected,
    BadSecureChannelIdInvalid,
    BadInvalidTimestamp,
    BadNonceInvalid,
    BadSessionIdInvalid,
    BadSessionClosed,
    BadSessionNotActivated,
    BadSubscriptionIdInvalid,
    BadRequestHeaderInvalid,
    BadTimestampsToReturnInvalid,
    BadRequestCancelledByClient,
    BadTooManyArguments,

    // License related
    BadLicenseExpired,
    BadLicenseLimitsExceeded,
    BadLicenseNotAvailable,

    // Communication related
    BadNoCommunication,
    BadWaitingForInitialData,

    // Node related
    BadNodeIdInvalid,
    BadNodeIdUnknown,
    BadAttributeIdInvalid,
    BadIndexRangeInvalid,
    BadIndexRangeNoData,
    BadDataEncodingInvalid,
    BadDataEncodingUnsupported,
    BadNotReadable,
    BadNotWritable,
    BadOutOfRange,
    BadNotSupported,
    BadNotFound,
    BadObjectDeleted,
    BadNotImplemented,

    // Monitoring related
    BadMonitoringModeInvalid,
    BadMonitoredItemIdInvalid,
    BadMonitoredItemFilterInvalid,
    BadMonitoredItemFilterUnsupported,
    BadFilterNotAllowed,
    BadStructureMissing,
    BadEventFilterInvalid,
    BadContentFilterInvalid,

    // Filter related
    BadFilterOperatorInvalid,
    BadFilterOperatorUnsupported,
    BadFilterOperandCountMismatch,
    BadFilterOperandInvalid,
    BadFilterElementInvalid,
    BadFilterLiteralInvalid,
    BadContinuationPointInvalid,
    BadNoContinuationPoints,

    // Browse related
    BadReferenceTypeIdInvalid,
    BadBrowseDirectionInvalid,
    BadNodeNotInView,
    BadNumericOverflow,
    BadServerUriInvalid,
    BadServerNameMissing,
    BadDiscoveryUrlMissing,
    BadSemaphoreFileMissing,

    // Security related
    BadRequestTypeInvalid,
    BadSecurityModeRejected,
    BadSecurityPolicyRejected,
    BadTooManySessions,
    BadUserSignatureInvalid,
    BadApplicationSignatureInvalid,
    BadNoValidCertificates,
    BadIdentityChangeNotSupported,
    BadRequestCancelledByRequest,

    // Node operations
    BadParentNodeIdInvalid,
    BadReferenceNotAllowed,
    BadNodeIdRejected,
    BadNodeIdExists,
    BadNodeClassInvalid,
    BadBrowseNameInvalid,
    BadBrowseNameDuplicated,
    BadNodeAttributesInvalid,
    BadTypeDefinitionInvalid,
    BadSourceNodeIdInvalid,
    BadTargetNodeIdInvalid,
    BadDuplicateReferenceNotAllowed,
    BadInvalidSelfReference,
    BadReferenceLocalOnly,
    BadNoDeleteRights,

    // View related
    BadServerIndexInvalid,
    BadViewIdUnknown,
    BadViewTimestampInvalid,
    BadViewParameterMismatch,
    BadViewVersionInvalid,
    BadNotTypeDefinition,
    BadTooManyMatches,
    BadQueryTooComplex,
    BadNoMatch,
    BadMaxAgeInvalid,
    BadSecurityModeInsufficient,

    // History related
    BadHistoryOperationInvalid,
    BadHistoryOperationUnsupported,
    BadInvalidTimestampArgument,
    BadWriteNotSupported,
    BadTypeMismatch,
    BadMethodInvalid,
    BadArgumentsMissing,
    BadNotExecutable,

    // Subscription related
    BadTooManySubscriptions,
    BadTooManyPublishRequests,
    BadNoSubscription,
    BadSequenceNumberUnknown,
    BadMessageNotAvailable,
    BadInsufficientClientProfile,
    BadStateNotActive,
    BadAlreadyExists,

    // TCP related
    BadTcpServerTooBusy,
    BadTcpMessageTypeInvalid,
    BadTcpSecureChannelUnknown,
    BadTcpMessageTooLarge,
    BadTcpNotEnoughResources,
    BadTcpInternalError,
    BadTcpEndpointUrlInvalid,
    BadRequestInterrupted,
    BadRequestTimeout,
    BadSecureChannelClosed,
    BadSecureChannelTokenUnknown,
    BadSequenceNumberInvalid,
    BadProtocolVersionUnsupported,

    // Device/Sensor related
    BadConfigurationError,
    BadNotConnected,
    BadDeviceFailure,
    BadSensorFailure,
    BadOutOfService,
    BadDeadbandFilterInvalid,

    // Condition related
    BadRefreshInProgress,
    BadConditionAlreadyDisabled,
    BadConditionAlreadyEnabled,
    BadConditionDisabled,
    BadEventIdUnknown,
    BadEventNotAcknowledgeable,
    BadDialogNotActive,
    BadDialogResponseInvalid,
    BadConditionBranchAlreadyAcked,
    BadConditionBranchAlreadyConfirmed,
    BadConditionAlreadyShelved,
    BadConditionNotShelved,
    BadShelvingTimeOutOfRange,

    // Data related
    BadNoData,
    BadBoundNotFound,
    BadBoundNotSupported,
    BadDataLost,
    BadDataUnavailable,
    BadEntryExists,
    BadNoEntryExists,
    BadTimestampNotSupported,

    // Aggregate related
    BadAggregateListMismatch,
    BadAggregateNotSupported,
    BadAggregateInvalidInputs,
    BadAggregateConfigurationRejected,

    // Request related
    BadRequestNotAllowed,
    BadRequestNotComplete,
    BadTransactionPending,
    BadTicketRequired,
    BadTicketInvalid,
    BadLocked,

    // Value change related
    BadDominantValueChanged,
    BadDependentValueChanged,
    BadEditedOutOfRange,
    BadInitialValueOutOfRange,
    BadOutOfRangeDominantValueChanged,
    BadEditedOutOfRangeDominantValueChanged,
    BadOutOfRangeDominantValueChangedDependentValueChanged,
    BadEditedOutOfRangeDominantValueChangedDependentValueChanged,

    // Connection related
    BadInvalidArgument,
    BadConnectionRejected,
    BadDisconnect,
    BadConnectionClosed,
    BadInvalidState,
    BadEndOfStream,
    BadNoDataAvailable,
    BadWaitingForResponse,
    BadOperationAbandoned,
    BadExpectedStreamToBlock,
    BadWouldBlock,
    BadSyntaxError,
    BadMaxConnectionsReached,

    // DataSet related
    BadDataSetIdInvalid,
};

/// Convert a status code to a Zig error or void
pub fn checkStatus(status: StatusCode) OpcUaError!void {
    if (status == GOOD) return;

    // Check if it's a GOOD variant (0x00xxxxxx)
    if ((status & 0xFF000000) == 0x00000000) return;

    return switch (status) {
        // Uncertain codes
        UNCERTAIN => OpcUaError.Uncertain,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINREFERENCENOTDELETED) => OpcUaError.UncertainReferenceNotDeleted,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINNOTALLNODESAVAILABLE) => OpcUaError.UncertainNotAllNodesAvailable,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINREFERENCEOUTOFSERVER) => OpcUaError.UncertainReferenceOutOfServer,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINNOCOMMUNICATIONLASTUSABLEVALUE) => OpcUaError.UncertainNoCommunicationLastUsableValue,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINLASTUSABLEVALUE) => OpcUaError.UncertainLastUsableValue,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINSUBSTITUTEVALUE) => OpcUaError.UncertainSubstituteValue,
        toStatusCode(c.UA_STATUSCODE_UNCERTAININITIALVALUE) => OpcUaError.UncertainInitialValue,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINSENSORNOTACCURATE) => OpcUaError.UncertainSensorNotAccurate,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINENGINEERINGUNITSEXCEEDED) => OpcUaError.UncertainEngineeringUnitsExceeded,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINSUBNORMAL) => OpcUaError.UncertainSubnormal,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINDATASUBNORMAL) => OpcUaError.UncertainDataSubnormal,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINDOMINANTVALUECHANGED) => OpcUaError.UncertainDominantValueChanged,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINDEPENDENTVALUECHANGED) => OpcUaError.UncertainDependentValueChanged,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINTRANSDUCERINMANUAL) => OpcUaError.UncertainTransducerInManual,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINSIMULATEDVALUE) => OpcUaError.UncertainSimulatedValue,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINSENSORCALIBRATION) => OpcUaError.UncertainSensorCalibration,
        toStatusCode(c.UA_STATUSCODE_UNCERTAINCONFIGURATIONERROR) => OpcUaError.UncertainConfigurationError,

        // Bad codes
        BAD => OpcUaError.BadUnexpectedError,
        toStatusCode(c.UA_STATUSCODE_BADUNEXPECTEDERROR) => OpcUaError.BadUnexpectedError,
        toStatusCode(c.UA_STATUSCODE_BADINTERNALERROR) => OpcUaError.BadInternalError,
        toStatusCode(c.UA_STATUSCODE_BADOUTOFMEMORY) => OpcUaError.BadOutOfMemory,
        toStatusCode(c.UA_STATUSCODE_BADRESOURCEUNAVAILABLE) => OpcUaError.BadResourceUnavailable,
        toStatusCode(c.UA_STATUSCODE_BADCOMMUNICATIONERROR) => OpcUaError.BadCommunicationError,
        toStatusCode(c.UA_STATUSCODE_BADENCODINGERROR) => OpcUaError.BadEncodingError,
        toStatusCode(c.UA_STATUSCODE_BADDECODINGERROR) => OpcUaError.BadDecodingError,
        toStatusCode(c.UA_STATUSCODE_BADENCODINGLIMITSEXCEEDED) => OpcUaError.BadEncodingLimitsExceeded,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTTOOLARGE) => OpcUaError.BadRequestTooLarge,
        toStatusCode(c.UA_STATUSCODE_BADRESPONSETOOLARGE) => OpcUaError.BadResponseTooLarge,
        toStatusCode(c.UA_STATUSCODE_BADUNKNOWNRESPONSE) => OpcUaError.BadUnknownResponse,
        toStatusCode(c.UA_STATUSCODE_BADTIMEOUT) => OpcUaError.BadTimeout,
        toStatusCode(c.UA_STATUSCODE_BADSERVICEUNSUPPORTED) => OpcUaError.BadServiceUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADSHUTDOWN) => OpcUaError.BadShutdown,
        toStatusCode(c.UA_STATUSCODE_BADSERVERNOTCONNECTED) => OpcUaError.BadServerNotConnected,
        toStatusCode(c.UA_STATUSCODE_BADSERVERHALTED) => OpcUaError.BadServerHalted,
        toStatusCode(c.UA_STATUSCODE_BADNOTHINGTODO) => OpcUaError.BadNothingToDo,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYOPERATIONS) => OpcUaError.BadTooManyOperations,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYMONITOREDITEMS) => OpcUaError.BadTooManyMonitoredItems,
        toStatusCode(c.UA_STATUSCODE_BADDATATYPEIDUNKNOWN) => OpcUaError.BadDataTypeIdUnknown,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEINVALID) => OpcUaError.BadCertificateInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSECURITYCHECKSFAILED) => OpcUaError.BadSecurityChecksFailed,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEPOLICYCHECKFAILED) => OpcUaError.BadCertificatePolicyCheckFailed,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATETIMEINVALID) => OpcUaError.BadCertificateTimeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEISSUERTIMEINVALID) => OpcUaError.BadCertificateIssuerTimeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEHOSTNAMEINVALID) => OpcUaError.BadCertificateHostNameInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEURIINVALID) => OpcUaError.BadCertificateUriInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEUSENOTALLOWED) => OpcUaError.BadCertificateUseNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEISSUERUSENOTALLOWED) => OpcUaError.BadCertificateIssuerUseNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEUNTRUSTED) => OpcUaError.BadCertificateUntrusted,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEREVOCATIONUNKNOWN) => OpcUaError.BadCertificateRevocationUnknown,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEISSUERREVOCATIONUNKNOWN) => OpcUaError.BadCertificateIssuerRevocationUnknown,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEREVOKED) => OpcUaError.BadCertificateRevoked,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEISSUERREVOKED) => OpcUaError.BadCertificateIssuerRevoked,
        toStatusCode(c.UA_STATUSCODE_BADCERTIFICATECHAININCOMPLETE) => OpcUaError.BadCertificateChainIncomplete,
        toStatusCode(c.UA_STATUSCODE_BADUSERACCESSDENIED) => OpcUaError.BadUserAccessDenied,
        toStatusCode(c.UA_STATUSCODE_BADIDENTITYTOKENINVALID) => OpcUaError.BadIdentityTokenInvalid,
        toStatusCode(c.UA_STATUSCODE_BADIDENTITYTOKENREJECTED) => OpcUaError.BadIdentityTokenRejected,
        toStatusCode(c.UA_STATUSCODE_BADSECURECHANNELIDINVALID) => OpcUaError.BadSecureChannelIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADINVALIDTIMESTAMP) => OpcUaError.BadInvalidTimestamp,
        toStatusCode(c.UA_STATUSCODE_BADNONCEINVALID) => OpcUaError.BadNonceInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSESSIONIDINVALID) => OpcUaError.BadSessionIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSESSIONCLOSED) => OpcUaError.BadSessionClosed,
        toStatusCode(c.UA_STATUSCODE_BADSESSIONNOTACTIVATED) => OpcUaError.BadSessionNotActivated,
        toStatusCode(c.UA_STATUSCODE_BADSUBSCRIPTIONIDINVALID) => OpcUaError.BadSubscriptionIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTHEADERINVALID) => OpcUaError.BadRequestHeaderInvalid,
        toStatusCode(c.UA_STATUSCODE_BADTIMESTAMPSTORETURNINVALID) => OpcUaError.BadTimestampsToReturnInvalid,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTCANCELLEDBYCLIENT) => OpcUaError.BadRequestCancelledByClient,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYARGUMENTS) => OpcUaError.BadTooManyArguments,
        toStatusCode(c.UA_STATUSCODE_BADLICENSEEXPIRED) => OpcUaError.BadLicenseExpired,
        toStatusCode(c.UA_STATUSCODE_BADLICENSELIMITSEXCEEDED) => OpcUaError.BadLicenseLimitsExceeded,
        toStatusCode(c.UA_STATUSCODE_BADLICENSENOTAVAILABLE) => OpcUaError.BadLicenseNotAvailable,
        toStatusCode(c.UA_STATUSCODE_BADNOCOMMUNICATION) => OpcUaError.BadNoCommunication,
        toStatusCode(c.UA_STATUSCODE_BADWAITINGFORINITIALDATA) => OpcUaError.BadWaitingForInitialData,
        toStatusCode(c.UA_STATUSCODE_BADNODEIDINVALID) => OpcUaError.BadNodeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADNODEIDUNKNOWN) => OpcUaError.BadNodeIdUnknown,
        toStatusCode(c.UA_STATUSCODE_BADATTRIBUTEIDINVALID) => OpcUaError.BadAttributeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADINDEXRANGEINVALID) => OpcUaError.BadIndexRangeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADINDEXRANGENODATA) => OpcUaError.BadIndexRangeNoData,
        toStatusCode(c.UA_STATUSCODE_BADDATAENCODINGINVALID) => OpcUaError.BadDataEncodingInvalid,
        toStatusCode(c.UA_STATUSCODE_BADDATAENCODINGUNSUPPORTED) => OpcUaError.BadDataEncodingUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADNOTREADABLE) => OpcUaError.BadNotReadable,
        toStatusCode(c.UA_STATUSCODE_BADNOTWRITABLE) => OpcUaError.BadNotWritable,
        toStatusCode(c.UA_STATUSCODE_BADOUTOFRANGE) => OpcUaError.BadOutOfRange,
        toStatusCode(c.UA_STATUSCODE_BADNOTSUPPORTED) => OpcUaError.BadNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADNOTFOUND) => OpcUaError.BadNotFound,
        toStatusCode(c.UA_STATUSCODE_BADOBJECTDELETED) => OpcUaError.BadObjectDeleted,
        toStatusCode(c.UA_STATUSCODE_BADNOTIMPLEMENTED) => OpcUaError.BadNotImplemented,
        toStatusCode(c.UA_STATUSCODE_BADMONITORINGMODEINVALID) => OpcUaError.BadMonitoringModeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADMONITOREDITEMIDINVALID) => OpcUaError.BadMonitoredItemIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADMONITOREDITEMFILTERINVALID) => OpcUaError.BadMonitoredItemFilterInvalid,
        toStatusCode(c.UA_STATUSCODE_BADMONITOREDITEMFILTERUNSUPPORTED) => OpcUaError.BadMonitoredItemFilterUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADFILTERNOTALLOWED) => OpcUaError.BadFilterNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADSTRUCTUREMISSING) => OpcUaError.BadStructureMissing,
        toStatusCode(c.UA_STATUSCODE_BADEVENTFILTERINVALID) => OpcUaError.BadEventFilterInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCONTENTFILTERINVALID) => OpcUaError.BadContentFilterInvalid,
        toStatusCode(c.UA_STATUSCODE_BADFILTEROPERATORINVALID) => OpcUaError.BadFilterOperatorInvalid,
        toStatusCode(c.UA_STATUSCODE_BADFILTEROPERATORUNSUPPORTED) => OpcUaError.BadFilterOperatorUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADFILTEROPERANDCOUNTMISMATCH) => OpcUaError.BadFilterOperandCountMismatch,
        toStatusCode(c.UA_STATUSCODE_BADFILTEROPERANDINVALID) => OpcUaError.BadFilterOperandInvalid,
        toStatusCode(c.UA_STATUSCODE_BADFILTERELEMENTINVALID) => OpcUaError.BadFilterElementInvalid,
        toStatusCode(c.UA_STATUSCODE_BADFILTERLITERALINVALID) => OpcUaError.BadFilterLiteralInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCONTINUATIONPOINTINVALID) => OpcUaError.BadContinuationPointInvalid,
        toStatusCode(c.UA_STATUSCODE_BADNOCONTINUATIONPOINTS) => OpcUaError.BadNoContinuationPoints,
        toStatusCode(c.UA_STATUSCODE_BADREFERENCETYPEIDINVALID) => OpcUaError.BadReferenceTypeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADBROWSEDIRECTIONINVALID) => OpcUaError.BadBrowseDirectionInvalid,
        toStatusCode(c.UA_STATUSCODE_BADNODENOTINVIEW) => OpcUaError.BadNodeNotInView,
        toStatusCode(c.UA_STATUSCODE_BADNUMERICOVERFLOW) => OpcUaError.BadNumericOverflow,
        toStatusCode(c.UA_STATUSCODE_BADSERVERURIINVALID) => OpcUaError.BadServerUriInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSERVERNAMEMISSING) => OpcUaError.BadServerNameMissing,
        toStatusCode(c.UA_STATUSCODE_BADDISCOVERYURLMISSING) => OpcUaError.BadDiscoveryUrlMissing,
        toStatusCode(c.UA_STATUSCODE_BADSEMPAHOREFILEMISSING) => OpcUaError.BadSemaphoreFileMissing,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTTYPEINVALID) => OpcUaError.BadRequestTypeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSECURITYMODEREJECTED) => OpcUaError.BadSecurityModeRejected,
        toStatusCode(c.UA_STATUSCODE_BADSECURITYPOLICYREJECTED) => OpcUaError.BadSecurityPolicyRejected,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYSESSIONS) => OpcUaError.BadTooManySessions,
        toStatusCode(c.UA_STATUSCODE_BADUSERSIGNATUREINVALID) => OpcUaError.BadUserSignatureInvalid,
        toStatusCode(c.UA_STATUSCODE_BADAPPLICATIONSIGNATUREINVALID) => OpcUaError.BadApplicationSignatureInvalid,
        toStatusCode(c.UA_STATUSCODE_BADNOVALIDCERTIFICATES) => OpcUaError.BadNoValidCertificates,
        toStatusCode(c.UA_STATUSCODE_BADIDENTITYCHANGENOTSUPPORTED) => OpcUaError.BadIdentityChangeNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTCANCELLEDBYREQUEST) => OpcUaError.BadRequestCancelledByRequest,
        toStatusCode(c.UA_STATUSCODE_BADPARENTNODEIDINVALID) => OpcUaError.BadParentNodeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADREFERENCENOTALLOWED) => OpcUaError.BadReferenceNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADNODEIDREJECTED) => OpcUaError.BadNodeIdRejected,
        toStatusCode(c.UA_STATUSCODE_BADNODEIDEXISTS) => OpcUaError.BadNodeIdExists,
        toStatusCode(c.UA_STATUSCODE_BADNODECLASSINVALID) => OpcUaError.BadNodeClassInvalid,
        toStatusCode(c.UA_STATUSCODE_BADBROWSENAMEINVALID) => OpcUaError.BadBrowseNameInvalid,
        toStatusCode(c.UA_STATUSCODE_BADBROWSENAMEDUPLICATED) => OpcUaError.BadBrowseNameDuplicated,
        toStatusCode(c.UA_STATUSCODE_BADNODEATTRIBUTESINVALID) => OpcUaError.BadNodeAttributesInvalid,
        toStatusCode(c.UA_STATUSCODE_BADTYPEDEFINITIONINVALID) => OpcUaError.BadTypeDefinitionInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSOURCENODEIDINVALID) => OpcUaError.BadSourceNodeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADTARGETNODEIDINVALID) => OpcUaError.BadTargetNodeIdInvalid,
        toStatusCode(c.UA_STATUSCODE_BADDUPLICATEREFERENCENOTALLOWED) => OpcUaError.BadDuplicateReferenceNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADINVALIDSELFREFERENCE) => OpcUaError.BadInvalidSelfReference,
        toStatusCode(c.UA_STATUSCODE_BADREFERENCELOCALONLY) => OpcUaError.BadReferenceLocalOnly,
        toStatusCode(c.UA_STATUSCODE_BADNODELETERIGHTS) => OpcUaError.BadNoDeleteRights,
        toStatusCode(c.UA_STATUSCODE_BADSERVERINDEXINVALID) => OpcUaError.BadServerIndexInvalid,
        toStatusCode(c.UA_STATUSCODE_BADVIEWIDUNKNOWN) => OpcUaError.BadViewIdUnknown,
        toStatusCode(c.UA_STATUSCODE_BADVIEWTIMESTAMPINVALID) => OpcUaError.BadViewTimestampInvalid,
        toStatusCode(c.UA_STATUSCODE_BADVIEWPARAMETERMISMATCH) => OpcUaError.BadViewParameterMismatch,
        toStatusCode(c.UA_STATUSCODE_BADVIEWVERSIONINVALID) => OpcUaError.BadViewVersionInvalid,
        toStatusCode(c.UA_STATUSCODE_BADNOTTYPEDEFINITION) => OpcUaError.BadNotTypeDefinition,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYMATCHES) => OpcUaError.BadTooManyMatches,
        toStatusCode(c.UA_STATUSCODE_BADQUERYTOOCOMPLEX) => OpcUaError.BadQueryTooComplex,
        toStatusCode(c.UA_STATUSCODE_BADNOMATCH) => OpcUaError.BadNoMatch,
        toStatusCode(c.UA_STATUSCODE_BADMAXAGEINVALID) => OpcUaError.BadMaxAgeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADSECURITYMODEINSUFFICIENT) => OpcUaError.BadSecurityModeInsufficient,
        toStatusCode(c.UA_STATUSCODE_BADHISTORYOPERATIONINVALID) => OpcUaError.BadHistoryOperationInvalid,
        toStatusCode(c.UA_STATUSCODE_BADHISTORYOPERATIONUNSUPPORTED) => OpcUaError.BadHistoryOperationUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADINVALIDTIMESTAMPARGUMENT) => OpcUaError.BadInvalidTimestampArgument,
        toStatusCode(c.UA_STATUSCODE_BADWRITENOTSUPPORTED) => OpcUaError.BadWriteNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADTYPEMISMATCH) => OpcUaError.BadTypeMismatch,
        toStatusCode(c.UA_STATUSCODE_BADMETHODINVALID) => OpcUaError.BadMethodInvalid,
        toStatusCode(c.UA_STATUSCODE_BADARGUMENTSMISSING) => OpcUaError.BadArgumentsMissing,
        toStatusCode(c.UA_STATUSCODE_BADNOTEXECUTABLE) => OpcUaError.BadNotExecutable,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYSUBSCRIPTIONS) => OpcUaError.BadTooManySubscriptions,
        toStatusCode(c.UA_STATUSCODE_BADTOOMANYPUBLISHREQUESTS) => OpcUaError.BadTooManyPublishRequests,
        toStatusCode(c.UA_STATUSCODE_BADNOSUBSCRIPTION) => OpcUaError.BadNoSubscription,
        toStatusCode(c.UA_STATUSCODE_BADSEQUENCENUMBERUNKNOWN) => OpcUaError.BadSequenceNumberUnknown,
        toStatusCode(c.UA_STATUSCODE_BADMESSAGENOTAVAILABLE) => OpcUaError.BadMessageNotAvailable,
        toStatusCode(c.UA_STATUSCODE_BADINSUFFICIENTCLIENTPROFILE) => OpcUaError.BadInsufficientClientProfile,
        toStatusCode(c.UA_STATUSCODE_BADSTATENOTACTIVE) => OpcUaError.BadStateNotActive,
        toStatusCode(c.UA_STATUSCODE_BADALREADYEXISTS) => OpcUaError.BadAlreadyExists,
        toStatusCode(c.UA_STATUSCODE_BADTCPSERVERTOOBUSY) => OpcUaError.BadTcpServerTooBusy,
        toStatusCode(c.UA_STATUSCODE_BADTCPMESSAGETYPEINVALID) => OpcUaError.BadTcpMessageTypeInvalid,
        toStatusCode(c.UA_STATUSCODE_BADTCPSECURECHANNELUNKNOWN) => OpcUaError.BadTcpSecureChannelUnknown,
        toStatusCode(c.UA_STATUSCODE_BADTCPMESSAGETOOLARGE) => OpcUaError.BadTcpMessageTooLarge,
        toStatusCode(c.UA_STATUSCODE_BADTCPNOTENOUGHRESOURCES) => OpcUaError.BadTcpNotEnoughResources,
        toStatusCode(c.UA_STATUSCODE_BADTCPINTERNALERROR) => OpcUaError.BadTcpInternalError,
        toStatusCode(c.UA_STATUSCODE_BADTCPENDPOINTURLINVALID) => OpcUaError.BadTcpEndpointUrlInvalid,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTINTERRUPTED) => OpcUaError.BadRequestInterrupted,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTTIMEOUT) => OpcUaError.BadRequestTimeout,
        toStatusCode(c.UA_STATUSCODE_BADSECURECHANNELCLOSED) => OpcUaError.BadSecureChannelClosed,
        toStatusCode(c.UA_STATUSCODE_BADSECURECHANNELTOKENUNKNOWN) => OpcUaError.BadSecureChannelTokenUnknown,
        toStatusCode(c.UA_STATUSCODE_BADSEQUENCENUMBERINVALID) => OpcUaError.BadSequenceNumberInvalid,
        toStatusCode(c.UA_STATUSCODE_BADPROTOCOLVERSIONUNSUPPORTED) => OpcUaError.BadProtocolVersionUnsupported,
        toStatusCode(c.UA_STATUSCODE_BADCONFIGURATIONERROR) => OpcUaError.BadConfigurationError,
        toStatusCode(c.UA_STATUSCODE_BADNOTCONNECTED) => OpcUaError.BadNotConnected,
        toStatusCode(c.UA_STATUSCODE_BADDEVICEFAILURE) => OpcUaError.BadDeviceFailure,
        toStatusCode(c.UA_STATUSCODE_BADSENSORFAILURE) => OpcUaError.BadSensorFailure,
        toStatusCode(c.UA_STATUSCODE_BADOUTOFSERVICE) => OpcUaError.BadOutOfService,
        toStatusCode(c.UA_STATUSCODE_BADDEADBANDFILTERINVALID) => OpcUaError.BadDeadbandFilterInvalid,
        toStatusCode(c.UA_STATUSCODE_BADREFRESHINPROGRESS) => OpcUaError.BadRefreshInProgress,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONALREADYDISABLED) => OpcUaError.BadConditionAlreadyDisabled,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONALREADYENABLED) => OpcUaError.BadConditionAlreadyEnabled,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONDISABLED) => OpcUaError.BadConditionDisabled,
        toStatusCode(c.UA_STATUSCODE_BADEVENTIDUNKNOWN) => OpcUaError.BadEventIdUnknown,
        toStatusCode(c.UA_STATUSCODE_BADEVENTNOTACKNOWLEDGEABLE) => OpcUaError.BadEventNotAcknowledgeable,
        toStatusCode(c.UA_STATUSCODE_BADDIALOGNOTACTIVE) => OpcUaError.BadDialogNotActive,
        toStatusCode(c.UA_STATUSCODE_BADDIALOGRESPONSEINVALID) => OpcUaError.BadDialogResponseInvalid,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONBRANCHALREADYACKED) => OpcUaError.BadConditionBranchAlreadyAcked,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONBRANCHALREADYCONFIRMED) => OpcUaError.BadConditionBranchAlreadyConfirmed,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONALREADYSHELVED) => OpcUaError.BadConditionAlreadyShelved,
        toStatusCode(c.UA_STATUSCODE_BADCONDITIONNOTSHELVED) => OpcUaError.BadConditionNotShelved,
        toStatusCode(c.UA_STATUSCODE_BADSHELVINGTIMEOUTOFRANGE) => OpcUaError.BadShelvingTimeOutOfRange,
        toStatusCode(c.UA_STATUSCODE_BADNODATA) => OpcUaError.BadNoData,
        toStatusCode(c.UA_STATUSCODE_BADBOUNDNOTFOUND) => OpcUaError.BadBoundNotFound,
        toStatusCode(c.UA_STATUSCODE_BADBOUNDNOTSUPPORTED) => OpcUaError.BadBoundNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADDATALOST) => OpcUaError.BadDataLost,
        toStatusCode(c.UA_STATUSCODE_BADDATAUNAVAILABLE) => OpcUaError.BadDataUnavailable,
        toStatusCode(c.UA_STATUSCODE_BADENTRYEXISTS) => OpcUaError.BadEntryExists,
        toStatusCode(c.UA_STATUSCODE_BADNOENTRYEXISTS) => OpcUaError.BadNoEntryExists,
        toStatusCode(c.UA_STATUSCODE_BADTIMESTAMPNOTSUPPORTED) => OpcUaError.BadTimestampNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADAGGREGATELISTMISMATCH) => OpcUaError.BadAggregateListMismatch,
        toStatusCode(c.UA_STATUSCODE_BADAGGREGATENOTSUPPORTED) => OpcUaError.BadAggregateNotSupported,
        toStatusCode(c.UA_STATUSCODE_BADAGGREGATEINVALIDINPUTS) => OpcUaError.BadAggregateInvalidInputs,
        toStatusCode(c.UA_STATUSCODE_BADAGGREGATECONFIGURATIONREJECTED) => OpcUaError.BadAggregateConfigurationRejected,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTNOTALLOWED) => OpcUaError.BadRequestNotAllowed,
        toStatusCode(c.UA_STATUSCODE_BADREQUESTNOTCOMPLETE) => OpcUaError.BadRequestNotComplete,
        toStatusCode(c.UA_STATUSCODE_BADTRANSACTIONPENDING) => OpcUaError.BadTransactionPending,
        toStatusCode(c.UA_STATUSCODE_BADTICKETREQUIRED) => OpcUaError.BadTicketRequired,
        toStatusCode(c.UA_STATUSCODE_BADTICKETINVALID) => OpcUaError.BadTicketInvalid,
        toStatusCode(c.UA_STATUSCODE_BADLOCKED) => OpcUaError.BadLocked,
        toStatusCode(c.UA_STATUSCODE_BADDOMINANTVALUECHANGED) => OpcUaError.BadDominantValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADDEPENDENTVALUECHANGED) => OpcUaError.BadDependentValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADEDITED_OUTOFRANGE) => OpcUaError.BadEditedOutOfRange,
        toStatusCode(c.UA_STATUSCODE_BADINITIALVALUE_OUTOFRANGE) => OpcUaError.BadInitialValueOutOfRange,
        toStatusCode(c.UA_STATUSCODE_BADOUTOFRANGE_DOMINANTVALUECHANGED) => OpcUaError.BadOutOfRangeDominantValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADEDITED_OUTOFRANGE_DOMINANTVALUECHANGED) => OpcUaError.BadEditedOutOfRangeDominantValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADOUTOFRANGE_DOMINANTVALUECHANGED_DEPENDENTVALUECHANGED) => OpcUaError.BadOutOfRangeDominantValueChangedDependentValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADEDITED_OUTOFRANGE_DOMINANTVALUECHANGED_DEPENDENTVALUECHANGED) => OpcUaError.BadEditedOutOfRangeDominantValueChangedDependentValueChanged,
        toStatusCode(c.UA_STATUSCODE_BADINVALIDARGUMENT) => OpcUaError.BadInvalidArgument,
        toStatusCode(c.UA_STATUSCODE_BADCONNECTIONREJECTED) => OpcUaError.BadConnectionRejected,
        toStatusCode(c.UA_STATUSCODE_BADDISCONNECT) => OpcUaError.BadDisconnect,
        toStatusCode(c.UA_STATUSCODE_BADCONNECTIONCLOSED) => OpcUaError.BadConnectionClosed,
        toStatusCode(c.UA_STATUSCODE_BADINVALIDSTATE) => OpcUaError.BadInvalidState,
        toStatusCode(c.UA_STATUSCODE_BADENDOFSTREAM) => OpcUaError.BadEndOfStream,
        toStatusCode(c.UA_STATUSCODE_BADNODATAAVAILABLE) => OpcUaError.BadNoDataAvailable,
        toStatusCode(c.UA_STATUSCODE_BADWAITINGFORRESPONSE) => OpcUaError.BadWaitingForResponse,
        toStatusCode(c.UA_STATUSCODE_BADOPERATIONABANDONED) => OpcUaError.BadOperationAbandoned,
        toStatusCode(c.UA_STATUSCODE_BADEXPECTEDSTREAMTOBLOCK) => OpcUaError.BadExpectedStreamToBlock,
        toStatusCode(c.UA_STATUSCODE_BADWOULDBLOCK) => OpcUaError.BadWouldBlock,
        toStatusCode(c.UA_STATUSCODE_BADSYNTAXERROR) => OpcUaError.BadSyntaxError,
        toStatusCode(c.UA_STATUSCODE_BADMAXCONNECTIONSREACHED) => OpcUaError.BadMaxConnectionsReached,
        toStatusCode(c.UA_STATUSCODE_BADDATASETIDINVALID) => OpcUaError.BadDataSetIdInvalid,
        else => OpcUaError.BadUnexpectedError,
    };
}

/// Check if a status code represents success (top 2 bits are 00)
pub fn isGood(status: StatusCode) bool {
    return (status >> 30) == 0x00;
}

/// Check if a status code represents an uncertain result (top 2 bits are 01)
pub fn isUncertain(status: StatusCode) bool {
    return (status >> 30) == 0x01;
}

/// Check if a status code represents a failure (top 2 bits are 10 or 11)
pub fn isBad(status: StatusCode) bool {
    return (status >> 30) >= 0x02;
}

/// Compare the top 16 bits of two status codes for equality
pub fn isEqualTop(s1: StatusCode, s2: StatusCode) bool {
    return (s1 & 0xFFFF0000) == (s2 & 0xFFFF0000);
}

// Unit Tests
const testing = std.testing;

test "toStatusCode converts c_int to StatusCode correctly" {
    const good = toStatusCode(c.UA_STATUSCODE_GOOD);
    try testing.expectEqual(@as(StatusCode, 0x00000000), good);

    const uncertain = toStatusCode(c.UA_STATUSCODE_UNCERTAIN);
    try testing.expectEqual(@as(StatusCode, 0x40000000), uncertain);

    const bad = toStatusCode(c.UA_STATUSCODE_BAD);
    try testing.expectEqual(@as(StatusCode, 0x80000000), bad);
}

test "checkStatus returns void for GOOD status" {
    try checkStatus(GOOD);
    try checkStatus(0x00000000);
    try checkStatus(0x00123456); // Any good variant
}

test "checkStatus returns correct errors for uncertain codes" {
    const result = checkStatus(UNCERTAIN);
    try testing.expectError(OpcUaError.Uncertain, result);

    const ref_not_deleted = checkStatus(toStatusCode(c.UA_STATUSCODE_UNCERTAINREFERENCENOTDELETED));
    try testing.expectError(OpcUaError.UncertainReferenceNotDeleted, ref_not_deleted);

    const last_usable = checkStatus(toStatusCode(c.UA_STATUSCODE_UNCERTAINLASTUSABLEVALUE));
    try testing.expectError(OpcUaError.UncertainLastUsableValue, last_usable);
}

test "checkStatus returns correct errors for bad codes" {
    const internal_error = checkStatus(toStatusCode(c.UA_STATUSCODE_BADINTERNALERROR));
    try testing.expectError(OpcUaError.BadInternalError, internal_error);

    const timeout = checkStatus(toStatusCode(c.UA_STATUSCODE_BADTIMEOUT));
    try testing.expectError(OpcUaError.BadTimeout, timeout);

    const node_unknown = checkStatus(toStatusCode(c.UA_STATUSCODE_BADNODEIDUNKNOWN));
    try testing.expectError(OpcUaError.BadNodeIdUnknown, node_unknown);

    const cert_invalid = checkStatus(toStatusCode(c.UA_STATUSCODE_BADCERTIFICATEINVALID));
    try testing.expectError(OpcUaError.BadCertificateInvalid, cert_invalid);
}

test "checkStatus returns BadUnexpectedError for unknown status codes" {
    const unknown = checkStatus(0x8FFF0000);
    try testing.expectError(OpcUaError.BadUnexpectedError, unknown);
}

test "isGood identifies good status codes" {
    try testing.expect(isGood(GOOD));
    try testing.expect(isGood(0x00000000));
    try testing.expect(isGood(0x00123456));
    try testing.expect(!isGood(UNCERTAIN));
    try testing.expect(!isGood(BAD));
    try testing.expect(!isGood(0x80340000));
}

test "isUncertain identifies uncertain status codes" {
    try testing.expect(isUncertain(UNCERTAIN));
    try testing.expect(isUncertain(0x40BC0000));
    try testing.expect(isUncertain(0x40900000));
    try testing.expect(!isUncertain(GOOD));
    try testing.expect(!isUncertain(BAD));
}

test "isBad identifies bad status codes" {
    try testing.expect(isBad(BAD));
    try testing.expect(isBad(0x80000000));
    try testing.expect(isBad(0x80340000));
    try testing.expect(isBad(0xC0000000)); // Also bad (top 2 bits = 11)
    try testing.expect(!isBad(GOOD));
    try testing.expect(!isBad(UNCERTAIN));
}

test "isEqualTop compares top 16 bits correctly" {
    try testing.expect(isEqualTop(0x80340000, 0x80340000));
    try testing.expect(isEqualTop(0x80340000, 0x80341234)); // Different bottom 16 bits
    try testing.expect(!isEqualTop(0x80340000, 0x80350000));
    try testing.expect(isEqualTop(GOOD, 0x00001234));
}

test "comprehensive status code mapping" {
    // Test a sample of each category to ensure mapping works

    // Certificate errors
    const cert_time = checkStatus(toStatusCode(c.UA_STATUSCODE_BADCERTIFICATETIMEINVALID));
    try testing.expectError(OpcUaError.BadCertificateTimeInvalid, cert_time);

    // Session errors
    const session_closed = checkStatus(toStatusCode(c.UA_STATUSCODE_BADSESSIONCLOSED));
    try testing.expectError(OpcUaError.BadSessionClosed, session_closed);

    // Node errors
    const not_writable = checkStatus(toStatusCode(c.UA_STATUSCODE_BADNOTWRITABLE));
    try testing.expectError(OpcUaError.BadNotWritable, not_writable);

    // TCP errors
    const tcp_timeout = checkStatus(toStatusCode(c.UA_STATUSCODE_BADREQUESTTIMEOUT));
    try testing.expectError(OpcUaError.BadRequestTimeout, tcp_timeout);

    // Device errors
    const device_failure = checkStatus(toStatusCode(c.UA_STATUSCODE_BADDEVICEFAILURE));
    try testing.expectError(OpcUaError.BadDeviceFailure, device_failure);

    // Connection errors
    const conn_rejected = checkStatus(toStatusCode(c.UA_STATUSCODE_BADCONNECTIONREJECTED));
    try testing.expectError(OpcUaError.BadConnectionRejected, conn_rejected);
}
