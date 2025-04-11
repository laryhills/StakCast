export default {
  atoma: {
    apiKey: process.env.ATOMA_KEY,
    model: process.env.ATOMA_MODEL,
  },
  port:process.env.PORT|| 1313,
  node_env:process.env.NODE_ENV||'development'
};
