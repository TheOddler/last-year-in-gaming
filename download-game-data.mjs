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
    let games = [];

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
            data: `fields name,first_release_date,summary,url,total_rating,rating,cover.image_id,websites.url,websites.category; where first_release_date >= ${oneYearAgo.unix()} & first_release_date <= ${oneMonthLater.unix()}; limit ${pageSize}; offset ${pageSize * page}; sort first_release_date asc;`
        });
        games.push(...gamesResponse.data);

        page++;
        if (gamesResponse.data < pageSize) break;
        await new Promise(resolve => setTimeout(resolve, 250)); // ensure we don't hit the request limit
    }
    console.log(`Downloaded ${page} page(s). Found ${games.length} games.`);


    console.log("Mapping data...")
    games = _.map(games, game => {
        // Category enum: https://api-docs.igdb.com/#website-enums
        const officialUrl = _.find(game.websites, website => website.category == 1 /*1 = official*/)?.url;
        const steam = _.find(game.websites, website => website.category == 13 /*13 = steam*/)?.url;
        const itch = _.find(game.websites, website => website.category == 15 /*15 = itch*/)?.url;
        const epicGames = _.find(game.websites, website => website.category == 16 /*16 = epicgames*/)?.url;
        const gog = _.find(game.websites, website => website.category == 17 /*17 = gog*/)?.url;

        if (officialUrl) { console.log(officialUrl); }

        return {
            name: game.name,
            description: game.summary,
            cover: game.cover?.image_id
                ? `https://images.igdb.com/igdb/image/upload/t_cover_big_2x/${game.cover.image_id}.jpg`
                : null,
            url: officialUrl,
            itch: itch,
            steam: steam,
            gog: gog,
            epic_games: epicGames,
            igdb: game.url,
            release_date: moment(parseInt(game.first_release_date) * 1000).format("YYYY-MM-DD")
        };
    });
    console.log("Done mapping data.")


    console.log("Grouping games by release date...");
    games = _.groupBy(games, 'release_date');
    console.log("Done grouping.");

    console.log("Writing files...");
    fs.mkdirSync(outputFolder, { recursive: true });
    for (let date in games) {
        const group = games[date];

        console.log(`...${date}...`);

        fs.writeFileSync(`${outputFolder}/${date}.json`, JSON.stringify(group, null, 2));
    }
    console.log("Done writing files.");
}
catch (e) {
    console.log(e.message);
    console.log(e.data);
}

