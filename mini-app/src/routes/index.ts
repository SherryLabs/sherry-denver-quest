import { Application } from "express";
import sherryRoutes from "./sherry.routes";

export default class Routes {
    constructor(app: Application) {
        app.use('/api/mini-app', sherryRoutes);
    }
}