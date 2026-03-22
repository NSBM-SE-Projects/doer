import app from './app';
import { createServer } from 'http';
import { initSocket } from './sockets';
import { connectRedis } from './config/redis';
import { startEscrowCron } from './utils/escrowCron';

const PORT = process.env.PORT || 3000;

const httpServer = createServer(app);
initSocket(httpServer);

const start = async () => {
  await connectRedis();
  startEscrowCron();
  httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

start();
