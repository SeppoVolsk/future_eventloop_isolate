import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void main(List<String> arguments) async {
  final stopwatch = Stopwatch()..start();
  print('st $stopwatch');

  /*
  Исполняются сразу, результат завернут во Future
  */
  final result = Future.value(5);
  Future.sync(() => print('sync'));

  /*
  Очередь микротасков выполняется после синхронных операций, раньше очереди эвентов
  */
  Future.microtask(() => print('mt1'));
  Future.microtask(() => print('mt2'));
  scheduleMicrotask((() => print('mt3')));

  /*
  Помещает в очередь эвентов только по прошествии времени (когда заканчивается запланированный таймер)
  */
  Future.delayed(Duration(seconds: 1), (() => print('Future 1 sec')));

  /*
  выполняются синхронно сразу после исполнения Future
  */
  Future(() => 'ordinary Future').then((value) => print('$value then'));
  Future(() => print('ordinary Future #2'))
      .whenComplete(() => print('whenComplete'));

  print((stopwatch..stop()).elapsedMilliseconds);

  print('Число потоков процессора: ${Platform.numberOfProcessors}');

  final isolate = await initIsolate();
  isolate.send('Hello world');

  //Завершает функцию(убивает текущий изолят)
  // exit(2);
}

Future<SendPort> initIsolate() async {
  final completer = Completer<SendPort>();

  // Создаём ReceivePort и начинаем его слушать
  final isolateToMainStream = ReceivePort();
  late StreamSubscription sub;
  sub = isolateToMainStream.listen((data) {
    if (data is SendPort) {
      final mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else {
      print('[Main Isolate] $data');
      //Отписываемся от ReceivePort и закрываем его
      //чтобы программа завершилась, т.к. в ЭвентЛупе не будет заданий в очередях
      //Т.е. помимо убийства изолята надо еще отписываться от него
      sub.cancel();
      isolateToMainStream.close();
    }
  });

  // Спавним изолят, передаем туда top-level функцию(которую будем выполнять в изоляте)
  // и передаем как аргумент/message SendPort (геттер из ReceivePort)
  final createIsolateInstance =
      await Isolate.spawn(createdIsolate, isolateToMainStream.sendPort);
  final sendPortFromIsolate = await completer.future;
  return sendPortFromIsolate;
}

void createdIsolate(SendPort isolateToMainStream) {
  // Это отдельный Event Loop
  // В этом изоляте создаём ReceivePort
  final mainToIsolateStream = ReceivePort();

  // Отправляем в исходный изолят SendPort этого изолята
  isolateToMainStream.send(mainToIsolateStream.sendPort);

  // Слушаем ReceivePort этого изолята, делаем принт,
  // отправляем это сообщение обратно
  mainToIsolateStream.listen((data) {
    print('[Created Isolate] $data');
    isolateToMainStream.send(data);

    // После первого полученного сообщения убиваем изолят
    // Если этого не сделать, то программа не завершится т.к.
    // оба изолята слушаю друг друга, нужна отписка
    Isolate.current.kill();
  });
}
