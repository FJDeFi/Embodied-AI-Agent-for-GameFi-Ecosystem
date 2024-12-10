require('dotenv').config();

const environments = {
  development: require('./development'),
  production: require('./production'),
  test: require('./test')
};

const currentEnv = process.env.NODE_ENV || 'development';

if (!environments[currentEnv]) {
  throw new Error(`Invalid environment: ${currentEnv}`);
}

// Add configuration validation
const Joi = require('joi');

const configSchema = Joi.object({
  port: Joi.number().default(5000),
  nodeEnv: Joi.string().valid('development', 'production', 'test').required(),
  infuraApiKey: Joi.string().required(),
  privateKey: Joi.string().pattern(/^0x[a-fA-F0-9]{64}$/).required(),
  contractAddress: Joi.string().pattern(/^0x[a-fA-F0-9]{40}$/).required(),
  maxGasLimit: Joi.number().default(6000000),
  maxRetries: Joi.number().default(3),
  requestTimeout: Joi.number().default(10000)
});

const { error, value: validatedConfig } = configSchema.validate(process.env);

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}

module.exports = validatedConfig; 