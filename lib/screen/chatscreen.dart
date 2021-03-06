import 'package:flutter/material.dart';
import 'package:chatbot/widget/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatbot/widget/header.dart';

class ChatScreen extends StatefulWidget {
  final String botName; final String name;
  ChatScreen(this.botName, this.name);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<Bubble> _messages = [];
  int cnt = -1; int size = 0;

  final _textController = TextEditingController();
  bool _isComposing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    for (Bubble message in _messages) {
      message.animationController.dispose();
    }
   super.dispose();
  }

  Bubble makeBubble(String name, String text, bool isMe){
    return Bubble(
          name: name,
          text: text,
          animationController: AnimationController(
            duration: Duration(milliseconds: 400),
            vsync: this,
          ),
          isMe: isMe
        );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    Bubble message = makeBubble("", text, true);
    setState(() {
      _messages.insert(0,message);
    });
    _focusNode.requestFocus();
    message.animationController.forward();
    if(size != 0 && cnt < size-1){
      ++cnt;
      this._answer();
    }
  }

  void _answer(){
    if(cnt == -1) return;
    firestore.collection(widget.botName)
    .orderBy('id').get()
    .then((querySnapshot) {
      
      var doc = querySnapshot.docs[cnt];
      
      Bubble rmsg = this.makeBubble(widget.name,doc.get('msg'), false);
      int sec = doc.get('msg').toString().length * 120; // 글자 길이에 따라 답장 속도
      Future.delayed(Duration(milliseconds: sec)).then((_) {
        setState(() {
          _messages.insert(0,rmsg);
        });
        rmsg.animationController.forward();
      });
      
    });
  }

  void getMsgSize(){
    firestore.collection(widget.botName)
    .get().then((snap) {
      size = snap.size;
    });
  }


  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Colors.black87),
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onChanged: (String text){
                setState((){
                  _isComposing = text.length > 0;
                });
              },
              onSubmitted: _handleSubmitted,
              decoration:  InputDecoration.collapsed(hintText: ''),
              focusNode: _focusNode,
              ),
            ),
          Container( 
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isComposing
                ? () => _handleSubmitted(_textController.text)
                : null,
            ), 
          )
        ]
      )
    ));
  }
  
  @override
  Widget build(BuildContext context){
    if(size == 0){ this.getMsgSize();}
    return Column(
      children: [
        Header(widget.name),
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse:true,
            itemBuilder: (_,int index) => _messages[index],
            itemCount: _messages.length,
          ),
        ),
        Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor
          ),
          child: _buildTextComposer(),
        )
      ],
    );
  }

}


