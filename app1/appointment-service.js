const express = require('express');
const app = express();

app.use(express.json());

// Sample data
let appointments = [
  { id: '1', patientId: '1', date: '2023-06-15', time: '10:00', doctor: 'Dr. Smith' },
  { id: '2', patientId: '2', date: '2023-06-16', time: '14:30', doctor: 'Dr. Johnson' }
];

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'Appointment Service' });
});

// All appointments
app.get('/appointments', (req, res) => {
  res.json({
    message: 'Appointments retrieved successfully',
    count: appointments.length,
    appointments: appointments
  });
});

// Appointment by ID
app.get('/appointments/:id', (req, res) => {
  const appointment = appointments.find(a => a.id === req.params.id);
  if (appointment) {
    res.json({
      message: 'Appointment found',
      appointment: appointment
    });
  } else {
    res.status(404).json({ error: 'Appointment not found' });
  }
});

// Create appointment
app.post('/appointments', (req, res) => {
  const { patientId, date, time, doctor } = req.body;

  if (!patientId || !date || !time || !doctor) {
    return res.status(400).json({ error: 'Patient ID, date, time, and doctor are required' });
  }

  const newAppointment = {
    id: (appointments.length + 1).toString(),
    patientId,
    date,
    time,
    doctor
  };

  appointments.push(newAppointment);

  res.status(201).json({
    message: 'Appointment scheduled successfully',
    appointment: newAppointment
  });
});

// Appointments by patient ID
app.get('/appointments/patient/:patientId', (req, res) => {
  const patientId = req.params.patientId;

  const result = appointments.filter(a => a.patientId === patientId);

  if (result.length > 0) {
    res.json({
      message: `Found ${result.length} appointment(s)`,
      appointments: result
    });
  } else {
    res.status(404).json({ message: `No appointments found for patient ${patientId}` });
  }
});

module.exports = app;
