import 'package:flutter/material.dart';

import 'managers/instance_manager.dart' as Stringee;

var user1 =
    'eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTSy4wLndkd29xU2R2UUEwSmNreGZYbHdZeXJMMG5yRUZSTklQLTE2NzkxMTQzODIiLCJpc3MiOiJTSy4wLndkd29xU2R2UUEwSmNreGZYbHdZeXJMMG5yRUZSTklQIiwiZXhwIjoxNjgxNzA2MzgyLCJ1c2VySWQiOiJwYXRpZW50XzQ4In0.V36FaRxcv6sFq4R93HZFgK27pgZ_1odVP5oE27ywbH4';

main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Notification Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? myUserId = "";

  @override
  void initState() {
    super.initState();
    Stringee.StringeeUtil.registEvents(context);
    Stringee.StringeeUtil.connect(user1);
  }

  @override
  Widget build(BuildContext context) {
    Widget topText = new Container(
      padding: EdgeInsets.only(left: 10.0, top: 10.0),
      child: new Text(
        'Connected as: $myUserId',
        style: new TextStyle(
          color: Colors.black,
          fontSize: 20.0,
        ),
      ),
    );

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("OneToOneCallSample"),
        backgroundColor: Colors.indigo[600],
      ),
      body: new Stack(
        children: <Widget>[topText, new ActionForm()],
      ),
    );
  }
}

class ActionForm extends StatefulWidget {
  @override
  _ActionFormState createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm> {
  @override
  Widget build(BuildContext context) {
    return new Form(
//      key: _formKey,
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Container(
            padding: EdgeInsets.all(20.0),
            child: new TextField(
              onChanged: (String value) {
                // toUserId = value;
              },
              decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  hintText: 'to'),
            ),
          ),
          new Container(
              margin: EdgeInsets.only(top: 20.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  new Container(
                    height: 40.0,
                    width: 150.0,
                    child: new ElevatedButton(
                      onPressed: () {
                        callTapped(false, false);
                      },
                      child: Text('CALL'),
                    ),
                  ),
                  new Container(
                    height: 40.0,
                    width: 150.0,
                    child: new ElevatedButton(
                      onPressed: () {
                        callTapped(true, false);
                      },
                      child: Text('VIDEOCALL'),
                    ),
                  ),
                ],
              )),
          new Container(
              margin: EdgeInsets.only(top: 20.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  new Container(
                    height: 40.0,
                    width: 150.0,
                    child: new ElevatedButton(
                      onPressed: () {
                        callTapped(false, true);
                      },
                      child: Text('CALL2'),
                    ),
                  ),
                  new Container(
                    height: 40.0,
                    width: 150.0,
                    child: new ElevatedButton(
                      onPressed: () {
                        callTapped(true, true);
                      },
                      child: Text('VIDEOCALL2'),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  void callTapped(bool isVideo, bool useCall2) {
    // if (toUserId.isEmpty || !Stringee.client.hasConnected) return;
    //
    // GlobalKey<CallScreenState> callScreenKey = GlobalKey<CallScreenState>();
    // if (isAndroid) {
    //   _androidCallManager!.callScreenKey = callScreenKey;
    // } else {
    //   _iOSCallManager!.callScreenKey = callScreenKey;
    // }
    //
    // CallScreen callScreen = CallScreen(
    //   key: callScreenKey,
    //   fromUserId: Stringee.client.userId,
    //   toUserId: toUserId,
    //   isVideo: isVideo,
    //   incoming: false,
    // );
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => callScreen),
    // );
  }
}
