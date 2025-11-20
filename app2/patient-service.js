const express = require("express");
const serverless = require("aws-serverless-express");

const app = express();
app.use(express.json());

// --- your existing express routes --- //
let patients = [
  { id: "1", name: "John Doe", age: 30, condition: "Healthy" },
  { id: "2", name: "Jane Smith", age: 45, condition: "Hypertension" }
];

app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", service: "Patient Service" });
});

app.get("/patients", (req, res) => {
  res.json({
    message: "Patients retrieved successfully",
    count: patients.length,
    patients
  });
});

app.get("/patients/:id", (req, res) => {
  const patient = patients.find((p) => p.id === req.params.id);
  patient
    ? res.json({ message: "Patient found", patient })
    : res.status(404).json({ error: "Patient not found" });
});

app.post("/patients", (req, res) => {
  try {
    const { name, age, condition } = req.body;
    if (!name || !age)
      return res.status(400).json({ error: "Name and age are required" });

    const newPatient = {
      id: (patients.length + 1).toString(),
      name,
      age,
      condition: condition || "Not specified"
    };
    patients.push(newPatient);
    res.status(201).json({
      message: "Patient added successfully",
      patient: newPatient
    });
  } catch (err) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// convert express app into lambda handler
const server = serverless.createServer(app);

exports.handler = (event, context) => {
  return serverless.proxy(server, event, context);
};
