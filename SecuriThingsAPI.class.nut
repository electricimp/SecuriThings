
const SECURITHINGS_EVT_USER    = 1;
const SECURITHINGS_EVT_DEVICE   = 2;

class SecuriThings {
    static version = [1,0,0];

    static URLROOT = "https://service.securithings.com/api/v1/event";

    _device_id = null;
    _device_type = null;
    _headers  = null;

    // Create a new SecuriThings client.
    //
    //  [string] apiKey: (mandatory) the api key given from SecuriThings.
    //  [string] apiSecret: (mandatory) the api secret given from SecuriThings.
    //  [string] deviceType: (mandatory) the device type. (for example "HVAC").
    //
    constructor(apiKey, apiSecret, deviceType) {

        if (apiKey == null || apiSecret == null) {
            server.error("Missing api key or api secret");
            return;
        }

        if (deviceType == null) {
            server.error("Missing device type");
            return;
        }

        _device_type = deviceType;
        _device_id = imp.configparams.deviceid;

        local authKey =  http.base64encode(apiKey + ":" + apiSecret);

        _headers = {"Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Basic " + authKey
        };
    }

    // Creates an event object that describes an event that is triggered by an external source (i.e. users).
    //
    //  [string] type: (mandatory) the type of the event or the action that is being performed (for example "setTemp").
    //  [table] httpRequest: (optional) the incoming HTTP request that was received in the http.onrequest callback.
    //
    // returns event object instance or null if there was an error
    function createExternalEvent(type, httpRequest = null) {

        local evt = SecuriThings.Event(type, SECURITHINGS_EVT_USER);

        local data = evt.getData();

        if (data == null)
            return null;

        // Set details from the http request.
        if (httpRequest != null) {
            data.rawset("SOURCE_IP", httpRequest.headers["x-forwarded-for"]);
            data.rawset("USER_AGENT", httpRequest.headers["user-agent"]);
        }

        return evt;
    }

    // Creates an event object that describes an event that is that is triggered by the imp device.
    //
    //  [string] type: (mandatory) the type of the event or the action that is being performed (for example "reportTemp").
    //
    // returns event object instance or null if there was an error
    function createDeviceEvent(type) {

        local evt = SecuriThings.Event(type, SECURITHINGS_EVT_DEVICE);

        if (evt.getData() == null)
            return null;

        return evt;
    };

    // Post an event to SecuriThings system for security monitoring. This methods makes an a-sync call to SecuriThings service.
    // For more information and examples about the fields, please visit https://securithings01.eastus.cloudapp.azure.com.
    //
    //  [SecuriThings.Event] event: (mandatory) an event object that was received from the SecuriThings.createExternalEvent or SecuriThings.createDeviceEvent methods.
    //  [function] callback: (mandatory) a callback for receiving the call status. the function will be invoked with a single parameter: a table with the same fields as the table returned by httprequest.sendsync().
    //
    // Returns true for success or false if an error has occured.
    //
    function sendEvent(event,callback) {

        if ( _device_type == null || _headers == null) {
            server.error("client not initialized");
            return false;
        }

        if (event == null) {
            server.error("missing event parameter");
            return false;
        }

        local eventDetails = event.getData();

        if (eventDetails == null) {
            server.error("invalid event parameter");
            return false;
        }

        // Add the device id and device type.
        eventDetails.rawset("DEVICE_ID", _device_id);
        eventDetails.rawset("DEVICE_TYPE", _device_type);

        // set event time as current time converted to milliseconds string.
        eventDetails.rawset("TIME", time() + "000");

        local body = http.jsonencode(eventDetails);
        local request = http.post(URLROOT, _headers, body);
        request.sendasync(callback);

        return true;
    }

    // An inner class to hold an event information.
    Event = class {

        _data = null;

        constructor(type, source) {

            local srcStr = null;

            if (type == null ) {
               server.error("missing event type parameter");
               return;
            }

            if (typeof type != "string" ) {
                server.error("event type must be a string");
                return;
            }

            if (source == SECURITHINGS_EVT_USER)
               srcStr = "USER";
            else if (source == SECURITHINGS_EVT_DEVICE)
               srcStr = "DEVICE";
            else {
                server.error("Event source parameter must be 'SECURITHINGS_EVT_USER' or 'SECURITHINGS_EVT_DEVICE'");
                return;
            }

            _data = {};
            _data.rawset("TYPE", type);
            _data.rawset("SOURCE", srcStr);
        }


        // Returns the full event data.
        function getData() {
            return _data;
        }

        // set id of the user performing the event.
        //
        //  [string] userId: the id of the user.
        //
        function setUserId(userId) {

            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (typeof userId != "string" ) {
                server.error("User ID must be string");
                return;
            }

            _data.rawset("USER_ID", userId);
        }

        // set the group to which the user or device belong to (for example factory_id or house_id).
        //
        //  [string] sourceGroupId: the id of the group.
        //
        function setSourceGroupID(sourceGroupId) {

            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (typeof sourceGroupId != "string" ) {
                server.error("Source group ID must be string");
                return;
            }

            _data.rawset("SOURCE_GROUP_ID", sourceGroupId);
        }

        // set the id of the api key that was used for sending the event on behalf of the user (for example IFTTT key id).
        //
        //  [string] apiKeyId: the id of the key that is used for this request.
        //
        function setApiKeyID(apiKeyId) {

            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (typeof sourceGatewayId != "string" ) {
                server.error("Api key ID must be string");
                return;
            }

            _data.rawset("SOURCE_GATEWAY_ID", apiKeyId);
        }

        // set session id of the event.
        //
        //  [string] sessionId: id of the session.
        //
        function setSessionID(sessionId) {


            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (typeof sessionId != "string" ) {
                server.error("Session ID must be integer");
                return;
            }


            _data.rawset("SESSION_ID", sessionId);
        }

        // set id of the event.
        //
        //  [string] extEvtId: id of the event.
        //
        function setExtEvtID(extEvtId) {

            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (typeof extEvtId != "string" ) {
                server.error("External event ID must be string");
                return;
            }

            _data.rawset("EXT_EVT_ID", extEvtId);
        }

        // Add an event parameter.
        //  [string] name : (mandatory) the name of the parameter.
        //  [string] value : (mandatory) the value of the parameter.
        function addParam(name, value) {

            if ( _data == null) {
                server.error("uninitialized event instance");
                return;
            }

            if (name == null || typeof name != "string" || value == null)
                return;

            if (typeof value != "string")
                value = value.tostring();

            local newParam = {
                "NAME" : name,
                "VALUE" : value
            };

            if (("PARAMS" in _data) == false)
                _data.rawset("PARAMS", []);

            _data["PARAMS"].append(newParam)
        }
    }
}
