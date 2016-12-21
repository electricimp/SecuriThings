
SecuriThings <- {};

class SecuriThings.Client {
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

        if (apiKey == null || apiSecret == null)
            throw "Missing api key or api secret";

		if (deviceType == null)
		    throw "Missing device type"

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
    function createExternalEvent(type, httpRequest = null) {

        local evt = SecuriThings.Event(type, SecuriThings.Event.USER);

        // Set details from the http request.
        if (httpRequest != null) {
            local data = evt.getData();
            data.rawset("SOURCE_IP", httpRequest.headers["x-forwarded-for"]);
            data.rawset("USER_AGENT", httpRequest.headers["user-agent"]);
        }

        return evt;

    }

    // Creates an event object that describes an event that is that is triggered by the imp device.
    //
    //  [string] type: (mandatory) the type of the event or the action that is being performed (for example "reportTemp").
    //
    function createDeviceEvent(type) {
       return SecuriThings.Event(type, SecuriThings.Event.DEVICE);
    };



    // Post an event to SecuriThings system for security monitoring. This methods makes an a-sync call to SecuriThings service.
    // For more information and examples about the fields, please visit https://securithings01.eastus.cloudapp.azure.com.
    //
    //  [SecuriThings.Event] event: (mandatory) an event object that was received from the SecuriThings.Client.createExternalEvent or SecuriThings.Client.createDeviceEvent methods.
    //  [function] callback: (mandatory) a callback for receiving the call status. the function will be invoked with a single parameter: a table with the same fields as the table returned by httprequest.sendsync().
    //
    // Returns Nothing.
    //
	function sendEvent(event,callback) {

	    local eventDetails = event.getData();

	    // Add the device id and device type.
	    eventDetails.rawset("DEVICE_ID", _device_id);
	    eventDetails.rawset("DEVICE_TYPE", _device_type);

	    // set event time as current time converted to milliseconds string.
	    eventDetails.rawset("TIME", time() + "000");


	    local body = http.jsonencode(eventDetails);
	    local request = http.post(URLROOT, _headers, body);
	    local response = request.sendasync(callback);

    }
}

// A class to hold an event information.
class SecuriThings.Event {

    static USER = 1;
    static DEVICE = 2;


    _data = null;

    constructor(type, source) {

        _data = {};

        if (type == null)
            throw "missing event type";

         _data.rawset("TYPE", type);

        if (source == USER)
            _data.rawset("SOURCE", "USER");
        else if (source == DEVICE)
            _data.rawset("SOURCE", "DEVICE");
        else
            throw "Event source must be 'Event.USER' or 'Event.DEVICE'";



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

        if (typeof userId != "string" )
            throw "User ID must be string";

        _data.rawset("USER_ID", userId);
    }

    // set the group to which the user or device belong to (for example factory_id or house_id).
    //
    //  [string] sourceGroupId: the id of the group.
    //
    function setSourceGroupID(sourceGroupId) {

        if (typeof sourceGroupId != "string" )
            throw "Source group ID must be string";

        _data.rawset("SOURCE_GROUP_ID", sourceGroupId);
    }

    // set the id of the api key that was used for sending the event on behalf of the user (for example IFTTT key id).
    //
    //  [string] apiKeyId: the id of the key that is used for this request.
    //
    function setApiKeyID(apiKeyId) {

        if (typeof sourceGatewayId != "string" )
            throw "Api key ID must be string";

        _data.rawset("SOURCE_GATEWAY_ID", apiKeyId);
    }

    // set session id of the event.
    //
    //  [string] sessionId: id of the session.
    //
    function setSessionID(sessionId) {

        if (typeof sessionId != "string" )
            throw "Session ID must be integer";

        _data.rawset("SESSION_ID", sessionId);
    }


    // set id of the event.
    //
    //  [string] extEvtId: id of the event.
    //
	function setExtEvtID(extEvtId) {

	    if (typeof extEvtId != "string" )
	        throw "External event ID must be string";

        _data.rawset("EXT_EVT_ID", extEvtId);
    }


	// Add an event parameter.
	//  [string] name : (mandatory) the name of the parameter.
	//  [string] value : (mandatory) the value of the parameter.
	function addParam(name, value) {

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

