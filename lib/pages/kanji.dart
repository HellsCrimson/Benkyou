import 'package:benkyo/pages/stats.dart';
import 'package:benkyo/widgets/const.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benkyo/category/kanji.dart';
import 'package:benkyo/notification_service.dart';
import 'package:benkyo/pages/historic.dart';

Kanji _words = Kanji();

class KanjiPage extends StatefulWidget {
  const KanjiPage({Key? key}) : super(key: key);

  State<KanjiPage> createState() => _KanjiPageState();
}

class _KanjiPageState extends State<KanjiPage> {
  NotificationService _notificationService = NotificationService();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  var text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getSavedSuccess();
    _getSavedFailure();
    _getSavedIndex();
    _getSavedFlags();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Const.BACKGROUND_COLOR,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    _words.getSymbol(),
                    style: TextStyle(
                      color: Const.TEXT_COLOR,
                      fontSize: 100,
                      shadows: <Shadow>[
                        Shadow(
                            color: Const.ICON_COLOR.withOpacity(0.3),
                            offset: Offset(0, 4),
                            blurRadius: 20)
                      ],
                    ),
                  ),
                  Text(_words.getMeaning(),
                      style: TextStyle(
                        color: Const.TEXT_COLOR,
                        fontSize: 45,
                      )),
                ],
              ),
              Column(children: [
                Text(
                  '${_words.getSuccessCount().toString()} success(es)',
                  style: TextStyle(
                    color: Const.TEXT_COLOR,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '${_words.getFailureCount().toString()} failure(s)',
                  style: TextStyle(
                    color: Const.TEXT_COLOR,
                    fontSize: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: text,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Const.TEXT_COLOR,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Const.TEXT_COLOR,
                        ),
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15),
                      isDense: true,
                      labelText: 'Answer',
                      labelStyle: TextStyle(
                        color: Const.TEXT_COLOR,
                      ),
                    ),
                    onSubmitted: (String value) async {
                      _notificationService.dailyNotification();
                      if (_checkAnswer(value)) {
                        await displaySuccessDialog(context, value);
                        _words.newWord();
                        _incrementSuccess();
                        _setSavedIndex();
                      } else {
                        await displayFailureDialog(context, value);
                        _words.newWord();
                        _incrementFailure();
                        _setSavedIndex();
                      }
                      setState(() {
                        text.clear();
                      });
                    },
                  ),
                ),
                getCheckMark(),
                getButtons(),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        _words.getHistory().then((value) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoricPage(
                                  history: value,
                                ),
                              ),
                            ));
                      },
                      child: Text('Historic'),
                    ),
                    TextButton(
                      onPressed: () {
                        _words.getHistory().then((value) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatsPage(
                                  symbolList: _words.list,
                                  history: value,
                                ),
                              ),
                            ));
                      },
                      child: Text("Stats"),
                    ),
                  ],
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }

  Future<void> displaySuccessDialog(BuildContext context, String value) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'おめでとう!',
            style: TextStyle(
              color: Const.TEXT_COLOR,
            ),
          ),
          content: Text(
            'You guessed correctly',
            style: TextStyle(
              color: Const.TEXT_COLOR,
            ),
          ),
          backgroundColor: Const.BACKGROUND_COLOR,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Const.TEXT_COLOR,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> displayFailureDialog(BuildContext context, String value) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Almost!',
            style: TextStyle(
              color: Const.TEXT_COLOR,
            ),
          ),
          content: Text(
            'You typed "$value" but it was "${_words.getLetter()}".',
            style: TextStyle(
              color: Const.TEXT_COLOR,
            ),
          ),
          backgroundColor: Const.BACKGROUND_COLOR,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Const.TEXT_COLOR,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  getButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          style: ButtonStyle(
            backgroundColor: Const.MAT_STATE_BUTTON_COLOR,
          ),
          onPressed: () {
            setState(() {
              _reset();
              text.clear();
            });
          },
          child: const Text("Reset"),
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: Const.MAT_STATE_BUTTON_COLOR,
          ),
          onPressed: () {
            setState(() {
              _words.newWord();
              _setSavedIndex();
              clearText();
            });
          },
          child: const Text("Pass"),
        ),
      ],
    );
  }

  getCheckMark() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
                activeColor: Const.ICON_COLOR,
                value: _words.kunPronunciation,
                side: BorderSide(
                  color: Const.ICON_COLOR,
                ),
                onChanged: (bool? value) {
                  setState(() {
                    _words.kunPronunciation = value!;
                    _setSavedFlags();
                  });
                }),
            Text(
              'Kun (Hiragana)',
              style: TextStyle(
                color: Const.TEXT_COLOR,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
                activeColor: Const.ICON_COLOR,
                value: !_words.kunPronunciation,
                side: BorderSide(
                  color: Const.ICON_COLOR,
                ),
                onChanged: (bool? value) {
                  setState(() {
                    _words.kunPronunciation = !value!;
                    _setSavedFlags();
                  });
                }),
            Text(
              'On (Katakana)',
              style: TextStyle(
                color: Const.TEXT_COLOR,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _checkAnswer(String answer) {
    return _words.checkAnswer(answer);
  }

  void _incrementSuccess() {
    setState(() {
      _words.setSuccessCount(_words.getSuccessCount() + 1);
    });
    _incrementSaved(
        '${_words.getTitle().toString()}_success', _words.getSuccessCount());
  }

  void _incrementFailure() {
    setState(() {
      _words.setFailureCount(_words.getFailureCount() + 1);
    });
    _incrementSaved(
        '${_words.getTitle().toString()}_failure', _words.getFailureCount());
  }

  _incrementSaved(String key, int value) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      prefs.setInt(key, value);
    });
  }

  _getSavedSuccess() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _words.setSuccessCount(
          prefs.getInt('${_words.getTitle().toString()}_success') ?? 0);
    });
  }

  _getSavedFailure() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _words.setFailureCount(
          prefs.getInt('${_words.getTitle().toString()}_failure') ?? 0);
    });
  }

  _getSavedIndex() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _words
          .setIndex(prefs.getInt('${_words.getTitle().toString()}_index') ?? 0);
    });
  }

  _setSavedIndex() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      prefs.setInt('${_words.getTitle().toString()}_index', _words.getIndex());
    });
  }

  _reset() {
    _incrementSaved('${_words.getTitle().toString()}_success', 0);
    _incrementSaved('${_words.getTitle().toString()}_failure', 0);
    _getSavedSuccess();
    _getSavedFailure();
  }

  clearText() {
    text.clear();
  }

  _getSavedFlags() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _words.setKunPronunciation(
          prefs.getBool('${_words.getTitle().toString()}_kun') ?? false);
    });
  }

  _setSavedFlags() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      prefs.setBool(
          '${_words.getTitle().toString()}_kun', _words.kunPronunciation);
    });
  }
}
