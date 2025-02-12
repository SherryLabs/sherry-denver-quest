import express, { Application } from 'express';
import Server from "./src/index";
import { config } from "dotenv";

config();

const app: Application = express();
const server: Server = new Server(app);
const PORT: number = process.env.PORT ? parseInt(process.env.PORT, 10) : 3002;

app
    .listen(PORT, () => {
        console.log(`Server is running on port ${PORT}`);
    })
    .on('error', (error: any) => {
        if (error.code === "EADDRINUSE") {
            console.log(`Port ${PORT} is already in use. Try another port.`);
        } else {
            console.log(error);
        }
    });