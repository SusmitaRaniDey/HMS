import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/data/models/appointment_model.dart';

void main() {
  test('patient join button is hidden after a meeting has started', () {
    final appointment = AppointmentModel(
      id: 1,
      date: DateTime.now().toIso8601String(),
      status: 'confirmed',
      type: 'online',
      zoomMeetingId: 'meeting-123',
      meetingStatus: 'started',
    );

    expect(appointment.canJoinMeeting, isFalse);
  });

  test('patient join button is still shown before the meeting starts', () {
    final appointment = AppointmentModel(
      id: 2,
      date: DateTime.now().toIso8601String(),
      status: 'confirmed',
      type: 'online',
      zoomMeetingId: 'meeting-123',
      meetingStatus: 'scheduled',
    );

    expect(appointment.canJoinMeeting, isTrue);
  });
}
