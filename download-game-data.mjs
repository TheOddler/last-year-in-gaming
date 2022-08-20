import axios from 'axios';
import moment from 'moment';
import fs from 'fs';
import _ from 'lodash';

// Base time for one year ago
const oneYearAgo = moment().subtract(1, 'years');
const oneMonthLater = oneYearAgo.clone().add(1, 'months');

// Add grace periods
oneYearAgo.subtract(3, 'days');
oneMonthLater.add(3, 'days');

// Log
console.log(`Downloading games data from ${oneYearAgo.format()} to ${oneMonthLater.format()}`);

const clientID = process.env.CLIENT_ID;
const clientSecret = process.env.CLIENT_SECRET;
const pageSize = 500;
const outputFolder = "public/data";


try {
    console.log("Authenticating...");
    const tokenResponse = await axios.post('https://id.twitch.tv/oauth2/token', {
        client_id: clientID,
        client_secret: clientSecret,
        grant_type: 'client_credentials'
    });
    const accessToken = tokenResponse.data.access_token;
    console.log("Authenticated.");

    let page = 0;
    const games = [];

    console.log(`Downloading games...`);
    while (true) {
        console.log(`...page ${page + 1}...`);
        const gamesResponse = await axios({
            url: 'https://api.igdb.com/v4/games',
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Client-ID': clientID,
                'Authorization': `Bearer ${accessToken}`,
            },
            data: `fields name,first_release_date,summary,url,total_rating,rating; where first_release_date >= ${oneYearAgo.unix()} & first_release_date <= ${oneMonthLater.unix()}; limit ${pageSize}; offset ${pageSize * page}; sort first_release_date asc;`
        });
        games.push(...gamesResponse.data);

        page++;
        if (gamesResponse.data < pageSize) break;
        await new Promise(resolve => setTimeout(resolve, 250)); // ensure we don't hit the request limit
    }
    console.log(`Downloaded ${page} page(s). Found ${games.length} games.`);

    console.log("Grouping games by release date...");
    const groupedGames = _.groupBy(games, 'first_release_date');
    console.log("Done grouping.");

    console.log("Writing files...");
    fs.mkdirSync(outputFolder, { recursive: true });
    for (let unixTime in groupedGames) {
        const group = groupedGames[unixTime];
        const date = moment(parseInt(unixTime) * 1000).format("YYYY-MM-DD");

        console.log(`...${date}...`);

        fs.writeFileSync(`${outputFolder}/${date}.json`, JSON.stringify(group, null, 2));
    }
    console.log("Done writing files.");
}
catch (e) {
    console.log(e.message);
    console.log(e.data);
}

