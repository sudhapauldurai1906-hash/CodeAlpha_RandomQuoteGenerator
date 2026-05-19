import mysql2 from "mysql2";
const conn=mysql2.createConnection({
    host:"localhost",
    port:3306,
    user:"root",
    password:"flower",
    database:"quoteapp"


}
);

export default conn;