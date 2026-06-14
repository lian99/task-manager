import { useState, useEffect } from "react";

function App() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch("http://localhost:3001/employees")
      .then((res) => {
        if (!res.ok) throw new Error("Failed to fetch employees");
        return res.json();
      })
      .then((data) => {
        setEmployees(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  if (loading) return <div style={styles.center}>Loading employees...</div>;
  if (error) return <div style={styles.center}>Error: {error}</div>;

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>Employee Task Summary</h1>
      <table style={styles.table}>
        <thead>
          <tr style={styles.headerRow}>
            <th style={styles.th}>Employee</th>
            <th style={styles.th}>Department</th>
            <th style={styles.th}>Total Tasks</th>
            <th style={styles.th}>Pending</th>
            <th style={styles.th}>In Progress</th>
            <th style={styles.th}>Done</th>
            <th style={styles.th}>Nearest Due Task</th>
          </tr>
        </thead>
        <tbody>
          {employees.map((emp) => (
            <tr key={emp.EmployeeID} style={styles.row}>
              <td style={styles.td}>{emp.FullName}</td>
              <td style={styles.td}>{emp.DepartmentName}</td>
              <td style={styles.td}>{emp.TotalTasks}</td>
              <td style={{ ...styles.td, color: "#e67e22", fontWeight: "bold" }}>
                {emp.PendingTasks}
              </td>
              <td style={{ ...styles.td, color: "#2980b9", fontWeight: "bold" }}>
                {emp.InProgressTasks}
              </td>
              <td style={{ ...styles.td, color: "#27ae60", fontWeight: "bold" }}>
                {emp.DoneTasks}
              </td>
              <td style={styles.td}>
                {emp.NearestDueTask
                  ? new Date(emp.NearestDueTask).toLocaleDateString()
                  : "—"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

const styles = {
  container: {
    fontFamily: "Arial, sans-serif",
    maxWidth: "1000px",
    margin: "40px auto",
    padding: "0 20px",
  },
  title: {
    textAlign: "center",
    color: "#2c3e50",
    marginBottom: "24px",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
    boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
  },
  headerRow: {
    backgroundColor: "#2c3e50",
    color: "white",
  },
  th: {
    padding: "12px 16px",
    textAlign: "left",
    fontWeight: "600",
  },
  row: {
    borderBottom: "1px solid #ecf0f1",
    backgroundColor: "white",
  },
  td: {
    padding: "12px 16px",
    color: "#2c3e50",
  },
  center: {
    textAlign: "center",
    marginTop: "100px",
    fontSize: "18px",
    color: "#7f8c8d",
  },
};

export default App;