import { eachWeekOfInterval, getYear, getWeek} from 'date-fns'
import Chumps from "./chumps";



function boutsByYearWeek(){
    let chumps = Chumps()

    // const startYear = getYear(new Date(Math.min(...chumps.map(e => new Date(e.parsedDate)))));
    const startYear = Math.min.apply(Math, chumps.map(function(bout) { return bout.date_year; }))




    const startDate = new Date(startYear, 0, 6);
    const endDate = new Date(); //today
    const endWeekNumber = getWeek(endDate)

    const dateRange = eachWeekOfInterval({
        start: startDate,
        end: endDate
    })

    // Load year/week-number skeleton
    let boutData = {}
    for(const weekStart of dateRange){
        let currentDate = new Date(weekStart)
        let currentYear = getYear(currentDate)
        let currentWeek = getWeek(currentDate, {firstWeekContainsDate: 7})
        if(!(currentYear in boutData)){
            boutData[currentYear] = {}
        }

        boutData[currentYear][currentWeek] = {chumps: []};
    }

    // Load bouts into out skeleton
    for(const bout of chumps){
        boutData[bout.date_year][bout.date_week] = bout;
    }
    return boutData;


}

export default boutsByYearWeek