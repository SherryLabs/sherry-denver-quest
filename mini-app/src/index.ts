import express, { Application } from 'express';
import cors, { CorsOptions } from 'cors';
import Routes from './routes/index';

export default class Server {
    constructor(app: Application) {
        this.config(app)
        new Routes(app);
    }

    private config(app: Application): void {
        const corsOptions: CorsOptions = {
            origin: '*', // This has to be changed to the domain of the mini app / Sherry's domain
            methods: 'GET'
        }

        app.use(cors(corsOptions));
        app.use(express.json());
        app.use(express.urlencoded({ extended: true }));
    }
}
