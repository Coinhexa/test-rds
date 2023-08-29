const fs = require("fs");
const path = require("path");
const pg = require("pg");
const { Sequelize } = require("sequelize-typescript");

pg.defaults.parseInt8 = true;

const database = process.env.POSTGRES_DB || "postgres";
const dialect = process.env.DB_DIALECT || "postgres";
const host = process.env.POSTGRES_HOST || "localhost";
const logger = console;
const password = process.env.POSTGRES_PASSWORD || "password";
const port = process.env.POSTGRES_PORT || 5432;
const rdsCa =
  process.env.POSTGRES_SSL === "true"
    ? fs.readFileSync(path.join(__dirname, "certs", "rds-ca-rsa2048-g1.pem"))
    : null;
const ssl =
  process.env.POSTGRES_SSL === "true"
    ? {
        rejectUnauthorized: true,
        ca: [rdsCa],
      }
    : false;
const username = process.env.POSTGRES_USER || "postgres";

const config = {
  dialect,
  username,
  password,
  database,
  host,
  port,
  define: {
    underscored: true,
  },
  logging: logger.log,
  dialectOptions: {
    ssl,
  },
};

const sequelize = new Sequelize({
  ...config,
});

(async function () {
  try {
    let response = await sequelize.query("SELECT 1 AS result", {
      type: sequelize.QueryTypes.SELECT,
    });
    logger.log("select 1", response);
    if (process.env.POSTGRES_SSL === "true") {
      response = await sequelize.query("SELECT ssl_is_used()", {
        type: sequelize.QueryTypes.SELECT,
      });
      logger.log("ssl_is_used", response[0].ssl_is_used);
    }
  } catch (error) {
    logger.error(error);
  } finally {
    await sequelize.close();
  }
})();
