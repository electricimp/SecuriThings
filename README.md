# SecuriThings

This library wraps the [SecuriThings](http://www.securithings.com) API - allowing real time IoT security monitoring for your ElectericImp devices.

**To add this library to your project, add** `#require "SecuriThings.class.nut:1.0.0"` **to the top of your agent code.**

## Description

SecuriThings utilizes behavior analytics to analyze human & machine behavior and detect threats in real-time.

This library provides an integration of the agent code to SecuriThings and enables monitoring of incoming HTTP requests to your agent and monitoring of imp device activities.

The SecuriThings namespace that is defined by this package include 2 class definitions:

 - SecuriThings.Client - This class provides the main functionality for sending events for security monitoring
 - SecuriThings.Event - A utility class that holds the event data that will be sent for analysis. Users should create instance of this class by invoking the *createExternalEvent()* or *createDeviceEvent()* of the Client class


## Agent Code Example

```squirrel

#require "SecuriThingsAPI.class.nut:1.0.0"

function monitoringResponse(response) {
    server.log("SecuriThings call status: " + response.statuscode );
}

// external http requests handler
function httpRequestHandler(request, response) {

    local userId = ... // extract user id from the request, authenticate it and make sure it has the required privileges

    server.log("got request: " + request.path);

    // handle power change requests
    if (request.path.find("/power/") == 0) {

        local state = request.path.slice("/power/".len())
        if (state != "on")
            state = "off";

        // send power command to the device
        device.send("power", state);

        // crete an event to send to SecuriThings monitoring service
        local event = client.createExternalEvent("power",request);

        // add any data that is available in this request with the appropriate setter methods
         // --------------------------------------------

        // user credentials were used to make this request
        event.setUserID(userId);

        // event parameter values
        event.addParam("state",state);

        // --------------------------------------------

        // send the event for security monitoring
        client.sendEvent(event, monitoringResponse);
    }

    // reply to the client with http 200 response
    response.send(200, "OK");
}

// device button press handler
function buttonHandler(state) {

    server.log("button state: " + state );

    // create a device event to send to SecuriThings monitoring service
    local event = client.createDeviceEvent("buttonState");

	// add any data that is available in this request with the appropriate setter methods
	 // --------------------------------------------

    // event parameter values
    event.addParam("pressed",state);

    // --------------------------------------------


    // send the event for security monitoring
    client.sendEvent(event, monitoringResponse);

}

// create a SecuriThings service client instance which is used in the above handler methods
client <- SecuriThings.Client("<SecuriThings api key>", "<SecuriThings api key secret>", "HVAC");

// register action handlers
device.on("buttonState", buttonHandler);
http.onrequest(httpRequestHandler);

```

## SecuriThings.Client

## Constructor: SecuriThings.Client(*apiKey, apiSecret, deviceType*)

In order to send events to the SecuriThings service you first need to create a client instance.

Contact [SecuriThings](http://www.securithings.com) in order to get *apiKey* and *apiSecret*.

The *deviceType* parameter is a string representing the device type that is being monitored (for example: "HVAC", "Lock").


```squirrel
#require "SecuriThingsAPI.class.nut:1.0.0"

// create a SecuriThings service client instance
client <- SecuriThings.Client("<SecuriThings api key>", "<SecuriThings api key secret>", "HVAC");
```

## Class Methods

###  sendEvent(*event, callback*)

This method sends an event to SecuriThings IoT security monitoring service.

The *event* parameter is an instance of *SecuriThings.Event* and it holds the event data. *SecuriThings.Event* obejcts can be created by invoking *createExternalEvent()* or *createDeviceEvent()* methods of *SecuriThings.Client* class.

The *callbcak* parameter is a function that will be executed upon completion of the request. It will be called with the following parameter:

| Name | Type | Description |
| ---- | ---- | ---- |
| *response* | Table | The returned response decoded into key-value pairs |

The available keys in the *response* parameter are:

| Key  | Type | Description |
| ---- | ---- | ---- |
| statuscode | Integer | HTTP status code (or libcurl error code) |
| headers | Table | Squirrel table of returned HTTP headers |
| body | String | Returned HTTP body (if any) |

More info for these values can be found in *[httprequest.sendasync()](https://electricimp.com/docs/api/httprequest/sendasync/)* documentation

### createExternalEvent(*type, [httpRequest]*)

This method returns an event object that can be used as a parameter to the *sendEvent()* method of this class.

Use this function to monitor events that originate from outside the agent code such as user http requests to the agent.

The *type* parameter gets a string with the event type that is being performed (for example: "power", "temperature", "lock").

The optional *httpRequest* parameter is the http request parameter that is passed to the *[http.onrequest()](https://electricimp.com/docs/api/http/onrequest/)* callback function.

The agent code can set additional event data on the returned object before passing it to the *sendEvent()* method by invoking its various setter methods.

```squirrel

// register action handlers
http.onrequest(httpRequestHandler);

// external http requests handler
function httpRequestHandler(request, response) {

    local userId = ... // extract user id from the request, authenticate it  and make sure it has the required privileges

    server.log("got request: " + request.path);

    // handle power change requests
    if (request.path.find("/power/") == 0) {

        local state = request.path.slice("/power/".len())
        if (state != "on")
            state = "off";

        // send power command to the device
        device.send("power", state);

        // crete an event to send to SecuriThings monitoring service
        local event = client.createExternalEvent("power",request);

        // add any data that is available in this request with the appropriate setter methods
         // --------------------------------------------

        // user credentials were used to make this request
        event.setUserID(userId);

        // event parameter values
        event.addParam("state",state);

        // --------------------------------------------

        // send the event for security monitoring
        client.sendEvent(event, monitoringResponse);
    }

    // reply to the client with http 200 response
    response.send(200, "OK");
}

```

### createDeviceEvent(*type*)

This method returns an event object that can be used as a parameter to the *sendEvent()* method of this class.

Use this function to monitor events that originate from the device.

The *type* parameter gets a string with the event type that is being reported by the device (for example: "buttonPress", "temperature", "systemArmChange").

```squirrel

// register action handlers
device.on("buttonState", buttonHandler);

// device button press handler
function buttonHandler(state) {

    server.log("button state: " + state +" of type " + typeof state );

    // create a device event to send to SecuriThings monitoring service
    local event = client.createDeviceEvent("buttonState");

    // add any data that is available in this request with the appropriate setter methods
     // --------------------------------------------

    // event parameter values
    event.addParam("pressed",state);

    // --------------------------------------------


    // send the event for security monitoring
    client.sendEvent(event, monitoringResponse);

}

```

## SecuriThings.Event

The *Event* class holds information about the event that is being performed.
Instances of this class are created by invoking the *createExternalEvent()* or *createDeviceEvent()* of the *SecuriThings.Client* class.

## Class Methods

### setUserId(*userId*)

Sets the id of the user performing the event

### setSourceGroupID(*sourceGroupId*)

Sets the group to which the user or device belong to (for example factory_id or house_id)

### setApiKeyID(*apiKeyId*)

Sets the id of the api key that was used for sending the event on behalf of the user (for example IFTTT key id)

### setSessionID(*sessionId*)

If the event originates from an http request that is part of a session - sets the session id in the event data

### setExtEvtID(*extEvtId*)

A system id for the event that is being monitored

### addParam(*name, value*)

Add event parameter value. Both *name* and *value* are mandatory. *name* must be a string. *value* can be string, integer or float.

## License

The SecuriThings library is licensed under the [MIT License](https://github.com/electricimp/thethingsapi/tree/master/LICENSE).
