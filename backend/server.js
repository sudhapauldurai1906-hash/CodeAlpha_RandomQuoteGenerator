import express from "express";
import mysql from "mysql2";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "flower",
  database: "quotes_db",
});

db.connect((err) => {
  if (err) console.log(err);
  else console.log("MySQL Connected");
});

// 🔵 GET
app.get("/quotes", (req, res) => {
  db.query("SELECT * FROM quotes", (err, result) => {
    if (err) return res.json(err);
    res.json({ result });
  });
});

// 🟢 POST
app.post("/addQuote", (req, res) => {
  const { text, author } = req.body;

  console.log("🔥 Received:", text, author); // 👈 ADD THIS

  const sql = "INSERT INTO quotes (text, author) VALUES (?, ?)";

  db.query(sql, [text, author], (err, result) => {
    if (err) {
      console.log(err);
      return res.json(err);
    }
    res.json("Added");
  });
});

// ✏️ PUT
app.put("/updateQuote/:id", (req, res) => {
  const { text, author } = req.body;
  const id = req.params.id;

  const sql = "UPDATE quotes SET text=?, author=? WHERE id=?";

  db.query(sql, [text, author, id], (err, result) => {
    if (err) return res.json(err);
    res.json("Updated");
  });
});

// 🗑️ DELETE
app.delete("/deleteQuote/:id", (req, res) => {
  const id = req.params.id;

  db.query("DELETE FROM quotes WHERE id=?", [id], (err, result) => {
    if (err) return res.json(err);
    res.json("Deleted");
  });
});

app.listen(2000, () => {
  console.log("Server running on port 2000");
});