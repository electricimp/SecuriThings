# SecuriThings

This library wraps the [SecuriThings](http://www.securithings.com/) API. SecuriThings provides real-time IoT security monitoring for your Electric Imp IoT devices.

SecuriThings analyzes human and machine behavior to detect threats in real time. The library allows you to monitor HTTP requests made to your agent and track device activities.

The library includes two class definitions:

 - SecuriThings &mdash; This class provides the main functionality for sending events for security checking.
 - SecuriThings.Event &mdash; This is an inner class that manages the event data that will be sent for analysis. You do not instantiate *Event* objects directly, but instead create instances of this class by invoking the *createExternalEvent()* or *createDeviceEvent()* methods of the outer class.

If you find any issues with the implementation, or if you have any questions about the library, please contact us at  [info@securithings.com](mailto:info@securithings.com).

**To add this library to your project, add** `#require "SecuriThingsAPI.class.nut:1.0.0"` **to the top of your agent code.**

## Library Usage

### Constructor: SecuriThings(*apiKey, apiSecret, deviceType*)

In order to send events to the SecuriThings service you first need to create a client instance. 

Visit [SecuriThings](http://www.securithings.com) in order to get your *apiKey* and *apiSecret*. The *deviceType* parameter is a string representing the device type that is being monitored: for example, "HVAC", "Thermostat", "Lock".

#### Example

```squirrel
#require "SecuriThingsAPI.class.nut:1.0.0"

// Create a SecuriThings service client instance
securithings <- SecuriThings("<Your SecuriThings API key>", "<Your SecuriThings API key secret>", "HVAC");
```

## Library Methods

### sendEvent(*event, callback*)

This method sends an event to SecuriThings IoT security monitoring service.

The *event* parameter is an instance of *SecuriThings.Event* and it holds the event data. *SecuriThings.Event* objects can be created by invoking the *createExternalEvent()* or *createDeviceEvent()* methods of the *SecuriThings* class.

The required *callback* parameter is a function that will be executed upon completion of the request. It will be called with a single parameter, *response*, which is table comprising the following key-value pairs:

| Key  | Type | Description |
| ---- | ---- | ---- |
| *statuscode* | Integer | HTTP status code (or libcurl error code) |
| *headers* | Table | Squirrel table of returned HTTP headers |
| *body* | String | Returned HTTP body (if any) |

More information on these values can be found in the [**httprequest.sendasync()**](https://electricimp.com/docs/api/httprequest/sendasync/) documentation.

This method returns `false` if there was an error sending the event, or `true` otherwise. If the method returned `true`, further status check should be performed within the *callback* function.

### createExternalEvent(*type[, httpRequest]*)

This method returns an event object that can be passed into the *sendEvent()* method’s *event* parameter. Use this method to monitor events that originate from outside the agent code, such as user HTTP requests to the agent.

The *type* parameter takes a string that indicates the event type that is being performed: for example, "power_on", "temperature_set", "lock_activate".

The optional *httpRequest* parameter is the same [**request**](https://electricimp.com/docs/api/httphandler/) parameter that is passed into the callback function registered by your agent code using [**http.onrequest()**](https://electricimp.com/docs/api/http/onrequest/).

The agent code can add additional event data to the returned object before passing it to the *sendEvent()* method by invoking its various setter methods, described below.

#### Example

```squirrel
// Register action handler
http.onrequest(httpRequestHandler);

// External HTTP requests handler
function httpRequestHandler(request, response) {
    // Extract the user's unique ID from the request, authenticate it 
    // and make sure it has the required privileges
    local userId = "<user ID>";

    server.log("Received request: " + request.path);

    // Handle power-change requests
    if (request.path.find("/power/") == 0) {
        local state = request.path.slice("/power/".len());
        if (state != "on") state = "off";

        // Send power command to the device
        device.send("power", state);

        // Create an event to send to SecuriThings monitoring service
        local event = securithings.createExternalEvent("power", request);

        // Add any data that is available in this request with the appropriate setter methods

        // Add the user credentials that were used to make this request
        event.setUserID(userId);

        // Add extra event parameter values
        event.addParam("state", state);

        // Send the event for security monitoring
        securithings.sendEvent(event, monitoringResponse);
    }

    // Reply to the client with HTTP 200 response
    response.send(200, "OK");
}

```

### createDeviceEvent(*type*)

This method returns an event object that can be passed into the *sendEvent()* method’s *event* parameter. Use this method to monitor events that originate from the device.

The *type* parameter takes a string indicating the event type that is being reported by the device: for example, "button_press", "temperature_reading", "system_arm_change".

#### Example

```squirrel
// Handler for device button presses
function buttonHandler(state) {
    server.log("Received button state: " + state);

    // Create a device event to send to SecuriThings monitoring service
    local event = securithings.createDeviceEvent("buttonState");

    // Add any data that is available in this request with the appropriate setter methods

    // Event parameter values
    event.addParam("pressed", state);

    // Send the event for security monitoring
    securithings.sendEvent(event, monitoringResponse);
}

// Register device action handlers
device.on("buttonState", buttonHandler);
```

## SecuriThings.Event Class

The *Event* class holds information about the event that is being performed. Instances of this class are created solely by invoking the *createExternalEvent()* or *createDeviceEvent()* methods of the library’s *SecuriThings* class.

## Class Methods

### setUserId(*userId*)

Sets the SecuriThings ID of the user performing the event.

### setSourceGroupID(*sourceGroupId*)

Sets the SecuriThings group to which the user or device belong to: for example, "factory_id" or "house_id".

### setApiKeyID(*apiKeyId*)

Sets the SecuriThings ID of the API key that was used for sending the event on behalf of the user.

### setSessionID(*sessionId*)

If the event originates from an HTTP request that is part of a session, this method adds the session ID to the event data.

### setExtEvtID(*extEvtId*)

A system ID for the event that is being monitored.

### addParam(*name, value*)

Add an event parameter value. Both *name* and *value* are mandatory: *name* must be a string; *value* can be a string, an integer or a float.

## Full Agent Code Example

```squirrel
#require "SecuriThingsAPI.class.nut:1.0.0"

function monitoringResponse(response) {
    server.log("SecuriThings call status: " + response.statuscode);
}

// External HTTP request handler
function httpRequestHandler(request, response) {
    // Extract the user's unique ID from the request, authenticate it 
    // and make sure it has the required privileges
    local userId = "<user ID>";

    server.log("Got request: " + request.path);

    // Handle power-change requests
    if (request.path.find("/power/") == 0) {
        local state = request.path.slice("/power/".len());
        if (state != "on") state = "off";

        // Send power command to the device
        device.send("power", state);

        // Create an event to send to SecuriThings monitoring service
        local event = securithings.createExternalEvent("power",request);

        // Add any data that is available in this request with the appropriate setter methods

        // Add the user credentials that were used to make this request
        event.setUserId(userId);

        // Add extra event parameter values
        event.addParam("state", state);

        // Send the event for security monitoring
        local result = securithings.sendEvent(event, monitoringResponse);
        if (!result) server.error("Error sending event");
    }

    // Reply to the client with HTTP 200 response
    response.send(200, "OK");
}

// Device button press handler
function buttonHandler(state) {
    server.log("Received button state: " + state);

    // Create a device event to send to SecuriThings monitoring service
    local event = securithings.createDeviceEvent("buttonState");

    // Add any data that is available in this request with the appropriate setter methods

    // Add extra event parameter values
    event.addParam("pressed", state);

    // Send the event for security monitoring
    local result = securithings.sendEvent(event, monitoringResponse);
    if (!result) server.error("Error sending event");
}

// *** PROGRAM START ***

// Create a SecuriThings service client instance
securithings <- SecuriThings("<Your SecuriThings API key>", "<Your SecuriThings API key secret>", "HVAC");

// Register action handlers
device.on("buttonState", buttonHandler);
http.onrequest(httpRequestHandler);
```

## License

The SecuriThings library is licensed under the [MIT License](https://github.com/electricimp/SecuriThings/blob/master/LICENSE).
