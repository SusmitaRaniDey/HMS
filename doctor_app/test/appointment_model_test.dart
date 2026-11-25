import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/doctor/data/models/appointment_model.dart';

void main() {
  test('doctor start meeting button is hidden after the meeting has ended', () {
    final appointment = AppointmentModel(
      id: 1,
      date: DateTime.now().toIso8601String(),
      status: 'confirmed',
      type: 'online',
      zoomMeetingId: 'meeting-123',
      meetingStatus: 'ended',
    );

    expect(appointment.canStartMeeting, isFalse);
  });

  test('doctor start meeting button is shown before the meeting ends', () {
    final appointment = AppointmentModel(
      id: 2,
      date: DateTime.now().toIso8601String(),
      status: 'confirmed',
      type: 'online',
      zoomMeetingId: 'meeting-123',
      meetingStatus: 'scheduled',
    );

    expect(appointment.canStartMeeting, isTrue);
  });
}
