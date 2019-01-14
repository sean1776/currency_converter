import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:currency_converter/storage.dart';
import 'package:country_icons/country_icons.dart';


typedef void fromToChangedCallback(String currencyName, String fromToDirection);

class HistoryList extends StatefulWidget {
  final historyStorage = HistoryStorge();
  List<String> items = [];
  final fromToChangedCallback onFromToChanged;

  HistoryList({@required this.onFromToChanged});

  void addItem(String item) {
    if (items.contains(item)) return;
    items.add(item);
  }

  void saveToHistoryStorage() {
    String history = '';
    print('saveToHistoryStorage() -> items.length: ${items.length}');    

    items.forEach((String item) {
      history =  history + item + '|';      
    });
    print('saveToHistoryStorage() -> saved string: $history');
    historyStorage.writeHistory(history);
  }

  @override
  HistoryListState createState() {
    return new HistoryListState();
  }
}

class HistoryListState extends State<HistoryList> {
  //final items = List<String>.generate(3, (i) => "Item ${i + 1}");
  
  void _readFromHistoryStorage() {    
    widget.historyStorage.readHistory().then((String history){      
      if (history == null) {
        print('_readFromHistoryStorage: history == null');
      } else if (history == '') {
        print('_readFromHistoryStorage: history: \'\' ');
      } else {

        if (history.contains('|')) {
          print('_readFromHistoryStorage: history has |');
        } else {
          print('_readFromHistoryStorage: history does not have |');
        }

        print('_readFromHistoryStorage: saved history: $history');
      }

      if (!history.contains('|')) return;

      var historyList = history.split('|');
      print('_readFromHistoryStorage() -> historyList.length: ${historyList.length}');
      if (historyList == null || historyList.length == 0) return;
      historyList.removeLast();

      historyList.forEach((String item){
        print('_readFromHistoryStorage() printing item: $item');
      });
      widget.items = historyList;
      setState((){});
    });
  }  

  @override
  initState() {
    super.initState();
    _readFromHistoryStorage();
    
  }

  @override 
  void dispose() {
    widget.saveToHistoryStorage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    
    // TODO: implement build
    

    print('build items.length: ${widget.items.length}');
    return ListView.builder(
      
      itemCount: widget.items.length + 1, // add Drawer Header
      //itemExtent: 20.0,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context, int index){
        if (index == 0) {
          return DrawerHeader(
            child: Text('Searched History', textAlign: TextAlign.center, style: TextStyle(fontSize: 25.0, color: Colors.white70),),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            padding: EdgeInsets.all(40.0),
          );
        }

        final listIndex = index - 1;
        final currencyName = widget.items[listIndex];
        print('items[index]: $currencyName');                
        final codeCountryArray = currencyName.split(' - ');
        print('codeCountryArray.length: ${codeCountryArray.length}');

        if (codeCountryArray.length != 2) {
          return Slidable(
            delegate: SlidableScrollDelegate(),
            child: Container(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: Text('$index'),
                ),
                title: Text('Error'),
                subtitle: Text('$currencyName'),
              ),
            ),
            actions: <Widget>[
            IconSlideAction(
              caption: 'Delete',
              icon: Icons.delete,
              color: Colors.red,
              onTap: (){
                setState(() {
                  widget.items.removeAt(listIndex);                           
                });              
              },
              //caption: 'Delete',
            ),
          ],
          );
        }
        
        final currencyCode = codeCountryArray[0];
        final currencyCounrty = codeCountryArray[1];

        Image currencyFlag;
        try {
          currencyFlag = Image.asset('icons/currency/${currencyCode.toLowerCase()}.png', package: 'currency_icons', width: 33.0, height: 22.0,);
        } catch (e) {
          print('catch an error');
        }
        
        

        if (currencyFlag == null) {
          print('history_list.dart line_149: currencyFlag == null');
        } else {
          print('history_list.dart line_149: currencyFlag != null');
        }

        return Slidable(
          delegate: SlidableScrollDelegate(),
          //actionExtentRatio: 0.25,
          child: Container(
            color: Colors.white,
            child: ListTile(
              leading: 
              CircleAvatar(backgroundColor: Colors.blue, foregroundColor: Colors.white, child: Text('$index'),),
              //currencyFlag,
              //Container(width: 33.0, height: 22.0, child: Image.asset('icons/currency/${currencyCode.toLowerCase()}.png', package: 'currency_icons'),),                            
              //leading: Image.asset('icons/flags/${currencyCode.toLowerCase()}.png', package: 'country_icons'),
              title: Text('$currencyCode'),
              subtitle: Text('$currencyCounrty'),
            ),
          ),
          actions: <Widget>[
            IconSlideAction(
              caption: 'Delete',
              icon: Icons.delete,
              color: Colors.red,
              onTap: (){
                setState(() {
                  widget.items.removeAt(listIndex);                          
                });              
              },
              //caption: 'Delete',
            ),
          ],
          secondaryActions: <Widget>[
            IconSlideAction(
              caption: 'From',
              icon: Icons.monetization_on,
              color: Colors.blue,
              onTap: (){
                print('blud coin tapped');
                widget.onFromToChanged(currencyName, 'From');
                Navigator.pop(context);
              },
            ),
            IconSlideAction(
              caption: 'To',
              icon: Icons.monetization_on,
              color: Colors.black,
              onTap: (){
                print('black coin tapped');
                widget.onFromToChanged(currencyName, 'To');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },      
    );
  }

}