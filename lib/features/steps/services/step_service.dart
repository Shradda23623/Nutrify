import 'package:pedometer/pedometer.dart';

class StepService {
  Stream<StepCount> getStepStream() {
    return Pedometer.stepCountStream;
  }
}