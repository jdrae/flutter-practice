import 'package:chatbot/widget/selcard.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/widget/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatbot/widget/header.dart';
import 'dart:async';
class Intro extends StatefulWidget {
  
  @override
  _IntroState createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<Widget> _messages = [];
  int cnt = -1; int size = 0;

  @override
  void dispose() {
    for (Bubble message in _messages) {
      message.animationController.dispose();
    }
   super.dispose();
  }

  @override
  void initState(){
    super.initState();
    if(size == 0){ this.getMsgSize('intro');}
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


  void _answer(coll){
    if(cnt == -1) return;
    firestore.collection(coll)
    .orderBy('id').get()
    .then((querySnapshot) {
      
      var doc = querySnapshot.docs[cnt];
      Bubble rmsg = this.makeBubble("나",doc.get('msg'), false);
      int sec = doc.get('msg').toString().length * 120; // 글자 길이에 따라 답장 속도
      if(sec > 2500) sec = 2500; //최대 속도 3초
      if(cnt == 0) sec = 100; // 처음일 경우 빨리

      Timer(Duration(milliseconds: sec),(){
        setState(() {
          _messages.insert(0,rmsg);
        });
        rmsg.animationController.forward();

        cnt += 1;
        if(cnt<size) this._answer(coll); //<size
        else if (coll=='intro'){
          SelCard sel = this.makeCard();
          Timer(Duration(milliseconds: 1500),(){
            setState((){
              _messages.insert(0,sel);
            });
            sel.animationController.forward();
          });
        }
      });
    });
  }

  SelCard makeCard(){
    return SelCard(
      qcards: [
        QCard(text: "나와\n대화하기", todo: "/me"),
        QCard(text: "너와\n대화하기", todo: "/you"),
        QCard(text: "우리와\n대화하기", todo: "/we")
      ],
      animationController: AnimationController(
        duration: Duration(milliseconds: 400),
        vsync: this,
      ),
      callback: (){
        this.getMsgSize('mebot');
      }
    );
  }

  void getMsgSize(coll){
    firestore.collection(coll)
    .get().then((snap) {
      size = snap.size;
    });
    cnt = 0;
    this._answer(coll);
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
              readOnly: true,
              decoration:  InputDecoration.collapsed(hintText: '메세지를 입력할 수 없습니다.'),
              ),
            ),
          Container( 
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed:  null,
            ), 
          )
        ]
      )
    ));
  }
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SizedBox(
          width: 400,
          height: 600,
          child: Card(
            child:
              Column(
                children: [
                  Header("나"),
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
              ),
          ),
        ),
      ),
    );
    
  }

}


