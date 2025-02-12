import { Router } from "express";
import { miniApp } from "../controllers/sherry.controller";

class SherryRoutes {
    public router: Router;

    constructor() {
        this.router = Router();
        this.init();
    }

    private init(): void {
        this.router.get('/', miniApp);
    }
}

export default new SherryRoutes().router;