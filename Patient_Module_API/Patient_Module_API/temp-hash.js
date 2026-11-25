const bcrypt = require('bcrypt');

bcrypt.hash('123456', 10)
  .then(hash => {
    console.log(hash);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
