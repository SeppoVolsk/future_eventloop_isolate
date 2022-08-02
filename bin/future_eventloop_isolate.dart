import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void main(List<String> arguments) {
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

  //Завершает функцию(убивает текущий изолят)
  // Isolate.current.kill();
  // exit(2);
}
