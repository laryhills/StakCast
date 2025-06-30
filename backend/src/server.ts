import app from './app';
import { config } from './config';

const PORT = config.port;

app.listen(PORT, () => {
    console.log(`Stakcast Backend API server listening on port ${PORT}`);
});
