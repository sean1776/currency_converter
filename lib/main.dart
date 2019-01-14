

import 'package:flutter/material.dart';
import 'package:currency_converter/storage.dart';
import 'package:currency_converter/post.dart';
import 'package:currency_converter/history_list.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome, rootBundle;
import 'package:ads/ads.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(primarySwatch: Colors.blue,),
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  Future<Post> post;
  final InputStorage storage = InputStorage();

  CurrencyConverter({Key key}) : super(key: key); 

  @override
  CurrencyConverterState createState() {
    return new CurrencyConverterState();
  }
}

class CurrencyConverterState extends State<CurrencyConverter> {
  Text amountLabel = Text('Amount');
  Text fromLabel = Text('From');
  Text toLabel = Text('To');

  String fromCurrencyName;
  String toCurrencyName;

  LinkedHashMap<String, String> currencyMap = LinkedHashMap<String, String>();

  @override
  void initState() {
    super.initState();
    widget.storage.readSavedInput().then((String savedInput){
      if (savedInput == null) return;
      print('savedInput: $savedInput');

      final fromToCurrency = savedInput.split('->');
      if (fromToCurrency.length == 2) {
        fromCurrencyName = fromToCurrency[0];
        toCurrencyName = fromToCurrency[1];
        print('initState() fromCurrencyName: $fromCurrencyName');
        print('initState() toCurrencyName: $toCurrencyName');
        if (fromCurrencyName == null || fromCurrencyName == '' || fromCurrencyName == 'null') {
          fromCurrencyName = 'TWD - New Taiwan Dollar';
          print('initState() fromCurrencyName == null');
        }
        if (toCurrencyName == null || toCurrencyName == '' || toCurrencyName == 'null') {
          toCurrencyName = 'USD - United States Dollar';
          print('initState() toCurrencyName == null');
        }

        print('initState() before setState()');
        print('initState() fromCurrencyName: $fromCurrencyName');
        print('initState() toCurrencyName: $toCurrencyName');
        setState((){});
      }
    });

    historyList = HistoryList(onFromToChanged: fromToChangedRequest,);

    Ads.init(
      'ca-app-pub-3280046000807573/7294211481',       
    );
    Ads.showBannerAd();
  }

  @override
  void dispose() {
    amountController.dispose();
    Ads.dispose();
    super.dispose();
  }

  final amountController = TextEditingController();
  TextFormField amountTextFormField;
  void createAmountTextFormField() {
    
    amountTextFormField = TextFormField(
      decoration: const InputDecoration(
        icon: Icon(Icons.attach_money),
        hintText: 'Enter a number',
        labelText: 'Amount',
      ),
      onSaved: (String value) {
        // This optional block of code can be used to run
        // code when the user saves the form.
      },
      validator: (String value) {
        return value.contains('@') ? 'Do not use the @ char.' : null;
      },
      keyboardType: TextInputType.number,
      controller: amountController,
    );
    setState((){});
  }

  DropdownButtonFormField<String> fromCurrency; 
  DropdownButtonFormField<String> toCurrency; 
  void createCurrencyDropDownFormField() {
    List<DropdownMenuItem<String>> currencyList = List<DropdownMenuItem<String>>();
    currencyMap.forEach((currencyCode, currencyDetail){
      String currencyName = '$currencyCode - $currencyDetail';
      DropdownMenuItem<String> currencyItem = DropdownMenuItem<String>(
        child: Container(
          child: Text(currencyName),
          width: MediaQuery.of(context).size.width - 70,
          ),
        value: currencyName,
      );
      currencyList.add(currencyItem); 
    });

    fromCurrency = DropdownButtonFormField<String>(
      items: currencyList,
      decoration: const InputDecoration(
        icon: Icon(Icons.monetization_on, color: Colors.blue,),
        labelText: 'From',
      ),
      onChanged: (item){
        historyList.addItem(item);
        fromCurrencyName = item;
        widget.storage.saveInput('$fromCurrencyName->$toCurrencyName');     
        historyList.saveToHistoryStorage();   
        setState((){});
      },
      value: fromCurrencyName,
      
    );
    toCurrency = DropdownButtonFormField<String>(
      items: currencyList,
      decoration: const InputDecoration(
        icon: Icon(Icons.monetization_on, color: Colors.black),
        labelText: 'To',        
      ),
      onChanged: (item){
        historyList.addItem(item);
        toCurrencyName = item;        
        widget.storage.saveInput('$fromCurrencyName->$toCurrencyName');
        historyList.saveToHistoryStorage();
        setState((){});
      },
      value: toCurrencyName,      
    );
    setState((){});
  }

  Text exchangeRateLabel = Text('Rate: ');
  Text exchangeRate;
  Icon resultLabel = Icon(Icons.attach_money,size: 50, color: Colors.black,);
  Text result;
  Text lastRefreshLabel;

  Row rateWidget;
  Row resultWidget;

  IconButton exchangeButton;
  IconButton submitButton;
  Widget loading;
  Row actionButtons;
  void createActionButtons() {
    exchangeButton = IconButton(
      icon: Icon(Icons.import_export),
      onPressed: (){
        print('exchange');
        
        String tmp = toCurrencyName;
        toCurrencyName = fromCurrencyName;
        fromCurrencyName = tmp;
        widget.storage.saveInput('$fromCurrencyName->$toCurrencyName');
        setState((){});
      },
    );

    submitButton = IconButton(
      icon: Icon(Icons.arrow_drop_down_circle, ),
      onPressed: (){
        loading = Text('loading');
        setState((){});

        print('submit');
        print('fromCurrencyName: $fromCurrencyName');
        print('toCurrencyName: $toCurrencyName');
        
        String fromCurrencyCode = fromCurrencyName.split(" - ")[0]; 
        String toCurrencyCode = toCurrencyName.split(" - ")[0];
        print('fromCurrencyCode: $fromCurrencyCode');
        print('toCurrencyCode: $toCurrencyCode');
        
        fetchPost(fromCurrencyCode, toCurrencyCode).then((post){
          print(post.exchangeRate);
          //print(post.lastRefreshed);
          exchangeRate = Text(double.parse(post.exchangeRate).toStringAsPrecision(4));
          var answer = double.parse(amountController.text) * double.parse(post.exchangeRate);
          
          var numberFormat = NumberFormat('###,###.##');
          //print('main.dart submitButton result length: ');
          //print(numberFormat.format(answer).length);
          if (numberFormat.format(answer).length > 10) {
            numberFormat = NumberFormat.scientificPattern();
          }
          

          result = Text(numberFormat.format(answer), style: TextStyle(color: Colors.black, fontSize: 50.0, fontWeight: FontWeight.w800),); 
          
          resultWidget = Row(children: <Widget>[
            Expanded(child: Text('')),
            resultLabel,
            result,
            Expanded(child: Text('')),
          ],);

          rateWidget = Row(children: <Widget>[
            Expanded(child: Text('')),
            exchangeRateLabel,
            exchangeRate,
            Expanded(child: Text('')),
          ],);

          lastRefreshLabel = Text('${post.lastRefreshed}', style: TextStyle(color: Colors.grey),);

          loading = null;
          setState((){});
        }).catchError((e){
          print('main.dart createActionButtons(): catched error:');
          print(e);

          result = Text('No Data', style: TextStyle(color: Colors.black, fontSize: 50.0, fontWeight: FontWeight.w800),); 
          resultWidget = Row(children: <Widget>[
            Expanded(child: Text('')),            
            result,
            Expanded(child: Text('')),
          ],);
          

          rateWidget = null;
          lastRefreshLabel = null;
          loading = null;
          setState((){});

        }); 
               
      },
    );

    actionButtons = Row(
      children: <Widget>[
        exchangeButton,
        Expanded(child: Text(''),),
        submitButton,   
        loading == null ? Text('') : CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.black),),     
        Expanded(child: Text(''),),                
      ],
    );
  }


  void loadCurrencyName() async {
    rootBundle.loadString('assets/currency_lists/physical_currency_list.csv').then((String contents){
      LinkedHashMap<String, String> physicalCurrencyMap = LinkedHashMap<String, String>();  
      var list = contents.split('\r\n');
      list.forEach((s){
       var keyValue = s.split(',');       
       
       if (keyValue.length == 2 && keyValue[0] != 'currency code') {         
         physicalCurrencyMap[keyValue[0]] = keyValue[1];
       }        
      });     
      currencyMap.addAll(physicalCurrencyMap);
      setState((){});  
    });

    rootBundle.loadString('assets/currency_lists/digital_currency_list.csv').then((String contents){
      LinkedHashMap<String, String> digitalCurrencyMap = LinkedHashMap<String, String>();  
      var list = contents.split('\r\n');
      list.forEach((s){
       var keyValue = s.split(',');       
       if (keyValue.length == 2 && keyValue[0] != 'currency code') {         
         digitalCurrencyMap[keyValue[0]] = keyValue[1];
       }        
      });      
      currencyMap.addAll(digitalCurrencyMap);
      setState((){});
      //digitalCurrencyMap.forEach((key, value){
      //  print('digitalCurrencyMap (key, value): ($key, $value)');
      //});
    });    
  }

  void createWidgets() async {
    loadCurrencyName();
    createAmountTextFormField();
    createCurrencyDropDownFormField();
    createActionButtons();
        
  }
/*
  FutureBuilder<Post> exchangeRate;  
  void getExchangeRate() {

    exchangeRate = FutureBuilder<Post>(
            future: widget.post,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print('snapshot has data');
                String exchangeRate = snapshot.data.exchangeRate;
                print('exchangeRate: $exchangeRate');
                return Text(exchangeRate);
              } else if (snapshot.hasError) {
                print('error!!');
                return Text("${snapshot.error}");
              }
              // By default, show a loading spinner
              return CircularProgressIndicator();
            }
    );
  }
*/

  void fromToChangedRequest(String currencyName, String fromToDirection) {     
    if (fromToDirection != 'From' && fromToDirection != 'To') return;

    if (fromToDirection == 'From') {
      fromCurrencyName = currencyName;      
    } else if (fromToDirection == 'To') {
      toCurrencyName = currencyName;      
    } 
    setState((){});
    widget.storage.saveInput('$fromCurrencyName->$toCurrencyName');    
  }

  var historyList; 
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    createWidgets();
   

    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      resizeToAvoidBottomPadding: false,
      drawer: Drawer(          
        child: historyList,
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            amountTextFormField,
            fromCurrency,              
            toCurrency,  
            actionButtons,  
            resultWidget == null ? Text('') : resultWidget,
            rateWidget == null ? Text('') : rateWidget,
            lastRefreshLabel == null ? Text('') : lastRefreshLabel,
          ],
        ),        
      ),
    );
  }
}
/**
 * 
 * 
 * 
 */