import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  print('가위, 바위, 보 중 하나를 정해서 입력해 주세요.');
  final String userInput = stdin.readLineSync(encoding: utf8) ?? 'Error';

  const selectList = ['가위', '바위', '보'];
  final cpuInput = selectList[Random().nextInt(3)];

  print(cpuInput);

  final result = getResult(userInput, cpuInput);
  print(result);
}

String getResult(String userInput, String cpuInput) {
  const cpuWin = 'CPU가 승리 하였습니다.';
  const playWin = 'Player가 승리 하였습니다.';
  const draw = '비겼습니다.';
  String result = draw;

  switch (userInput) {
    case '가위':
      if (cpuInput == '바위') {
        result = cpuWin;
      }

      if (cpuInput == '보') {
        result = playWin;
      }
    case '바위':
      if (cpuInput == '보') {
        result = cpuWin;
      }

      if (cpuInput == '가위') {
        result = playWin;
      }
    case '보':
      if (cpuInput == '가위') {
        result = cpuWin;
      }

      if (cpuInput == '바위') {
        result = playWin;
      }
    default:
      result = '올바른 값을 입력 해 주세요.';
  }

  return result;
}