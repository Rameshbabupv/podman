
Front end

    KEYCLOCK: {
        realm: 'Atex',
        url: 'http://erp.atex.in:8080/auth',
        clientId: 'HRMS'
    },

Back end

module.exports = {
    KEYCLOCK_SOS: {
        CONFIG: {
            URL: 'http://erp.atex.in:8080/auth',
            USERNAME: "systech",
            PASSWORD: "systech",
            REALM: 'Atex',
            CLIENT_ID: "HRMS",
            OPEN_CLIENT_ID_URL: "http://erp.atex.in:8080/auth/realms/master",
            OPEN_CLIENT_ID: 'admin-cli'
        }
    },
    MYSQL_SERVER: {
        host: '192.168.1.45',
        port: '3306',
        user: 'systech',
        password: 'systech',
        database: 'manju_db_2021'
    },
    EMAIL: {
        Email_ID: 'itsupport@atex.in',
        PASSWORD: 'Sana@atex',
        MailServer: 'mail.atex.in',
        PORT: 465,
    },
    MONGO_URL: 'mongodb://localhost:27017/Atexnew',
    PORT: 6070,
    PUNCH_CONFIG: {
        in: "in",
        out: "out"
    }
}

