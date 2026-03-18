import app from './app';
import { createServer } from 'http';
import { initSocket } from './sockets';
import { connectRedis } from './config/redis';

const PORT = process.env.PORT || 3000;

const httpServer = createServer(app);
initSocket(httpServer);

const start = async () => {
  await connectRedis();
  httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

start();
