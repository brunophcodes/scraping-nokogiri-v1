My Job Tracker
============================================

Project built to learn the use of Gemini AI and Notion API along with Ruby on Rails to track different role positions from the most known Ruby Job Boards: 

* [Ruby On Remote](https://rubyonremote.com/remote-jobs/) 
* [GoRails](https://jobs.gorails.com/)

## Introduction:

During my job search, I've been visiting these job boards a lot and copy/pasting the right information from the roles I found interesting in my Google Sheet or my Notion table (20 fields to fill) took me more like 5 minutes per job post.

After building this new tool, I reduced the time to 1 minute or less, depending on the job description length.

### DEMO

[![Watch the video](https://cdn.loom.com/sessions/thumbnails/aa2ad26494054c33aef0422db06f32d6-7423729d9d285bd5-full-play.gif)](https://www.loom.com/share/aa2ad26494054c33aef0422db06f32d6?sid=aafd07eb-9374-4713-9d7b-93a6c75b0016) 



## Tech Stack:


- Ruby 3.2.4
- Ruby on Rails 7.1.3
- Tailwind

| Gems       | Use |
| ---------- | --- |
| [nokogiri](https://github.com/sparklemotion/nokogiri) | Scraping job posts content |
| [notion-ruby-client](https://github.com/phacks/notion-ruby-client) | Connect with my personal Notion workspace and save the job posts information. |
| [gemini-ai](https://github.com/gbaptista/gemini-ai) | Leverage the job description summary and context |
| [redcarpet](https://github.com/vmg/redcarpet) | Markdown parser |

## How it works:

 1. You can go to any of these job boards and copy the URL of a job role.
     * [Ruby On Remote](https://rubyonremote.com/remote-jobs/) 
     * [GoRails](https://jobs.gorails.com/)
 2. Paste it on the text box and click the "Click me!" button
 3. You get a job description's summary and the key information and technologies on a card.
 4. You have the option to save this job on your Notion's Board view or to get back to the main page.


## Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/scraping-nokogiri-v1.git
   cd scraping-nokogiri-v1
   ```

2. **Install dependencies**
   ```bash
   bundle install
   yarn install
   ```

3. **Configure environment variables**
   - Fill in the following variables with your own credentials:
     - `NOTION_API_TOKEN` - Following the [Notion documentation for integration](https://developers.notion.com/docs/authorization) 
     - `NOTION_TARGET_DB` - Following the [Notion documentation for databases](https://developers.notion.com/docs/working-with-databases)
     - `NOTION_DB_VIEW`- Follow the documentation to make your [Notion's Table view public](https://www.notion.com/help/public-pages-and-web-publishing) and post the URL on this variable
     - `GOOGLE_API_KEY` for [Gemini AI API](https://ai.google.dev/gemini-api/docs/api-key)

4. **Start the Rails server**
   ```bash
   rails server
   ```

5. **Check the app**
   - Open [http://localhost:3000](http://localhost:3000) in your browser.
