import { Router } from "express";
import authRouter from "./Auth/auth.routes";
const v1: Router = Router();

v1.use("/auth", authRouter);

export default v1;
