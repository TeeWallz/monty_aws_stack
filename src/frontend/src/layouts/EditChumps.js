import React, { Component } from 'react';
// import {bindActionCreators} from 'redux'
// import {connect} from 'react-redux';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import classNames from 'classnames';
import moment from 'moment';

import DayCounter from "../components/monty_stats/DayCounter";
import combineStyles from "../utils/combineStyles";
import commonStyle from "../styles/common";
import CurrentChump from "../components/monty_stats/CurrentChump";
import MiniStats from "../components/monty_stats/MiniStats";
import CommentsContainer from "../components/social/CommentsContainer";
import ChumpHistory from "../components/history/ChumpHistory";
import HitBoxChart from "../components/monty_stats/HitBoxChart";
import StreakGraph from "../components/monty_stats/StreakGraph";
import LightboxExample from "../components/lightbox/Lightbox";
import Chumps from "../data/chumps";
import Links from "../components/social/Links";
import ContactMe from "../components/social/ContactMe";

const frontPageStyle = theme => ({
    header: {
        backgroundColor: '#fff5ee',
    },
    header_image: {
        width: '100%',
    },
    flex: {
        flex: 1
    },



});

const getBase64 = (file) => {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = error => reject(error);
        reader.readAsDataURL(file);
    });
}

const chump_template = {
    'date': '',
    'thanks': '',
    'image': '',
}

const new_bout_modes = {
    new_bout: "new_bout",
    confirm_date: "confirm_date",
}

class EditChumpsLayout extends Component {
    constructor(props) {
        super(props);
        console.log(props)

        let chumps_dict = props.props.chumps.reduce((obj, item) => (obj[item.date] = item, obj), {});
        let chump_dates = Object.keys(chumps_dict)

        this.state = {
            chump_dates: chump_dates,
            chumps_array: props.props.chumps,
            chumps_dict: chumps_dict,
            chumps_changes: {},
            selectedDate: props.props.chumps[0].date,
            new_bout_mode: new_bout_modes.new_bout,
            new_date: ''
        }
    }

    // componentDidMount = () => {
    //     var $this = $(ReactDOM.findDOMNode(this));
    // }

    onBoutListClick = (e) => {
        console.log(this.state.chumps_dict[e.target.value])
        this.setState({
            selectedDate: e.target.value
        });
    }

    addChumpChange = (field, value) => {
        // Is date in changes object? If not add it
        let current_changes = this.state.chumps_changes;

        if (!(this.state.selectedDate in current_changes)) {
            current_changes[this.state.selectedDate] = {}
        }
        current_changes[this.state.selectedDate][field] = value

        this.setState({
            chumps_changes: current_changes
        });
    }

    getFieldValue = (date, field) => {
        let kek = 1;
        // Assume no change at first
        let return_obj = { 'modified': false, value: this.state.chumps_dict[date][field] }

        if (this.state.selectedDate in this.state.chumps_changes) {
            if (field in this.state.chumps_changes[date]) {
                // If change exists for day and field, return it
                return_obj.modified = true;
                return_obj.value = this.state.chumps_changes[date][field];
            }
        }
        return return_obj;
    }

    imageUpload = (e) => {
        const file = e.target.files[0];
        console.log(file)
        let test = getBase64(file)
        console.log(test)
        getBase64(file).then(base64 => {
            this.addChumpChange('image', base64)
            console.log("file stored", base64);
        });
    }

    sortDict = (dict) => {
        // Step - 1
        // Create the array of key-value pairs
        var items = Object.keys(dict).map(
            (key) => { return [key, dict[key]] });

        // Step - 2
        // Sort the array based on the second element (i.e. the value)
        items.sort(
            (first, second) => { return first[1] - second[1] }
        );

        // Step - 3
        // Obtain the list of keys in sorted order of the values.
        var keys = items.map(
            (e) => { return e[0] });
    }


    generateChumpJson = () => {


    }

    onNewBoutButtonClick = () => {
        let kek = moment()
        let str = kek.format('YYYY-MM-DD');
        console.log(str)

        if (this.state.new_bout_mode == new_bout_modes.new_bout) {
            let today_date = moment()
            let today_str_iso = kek.format('YYYY-MM-DD');
            let past_date = moment(964400386)
            let date_to_use = today_date

            if (today_str_iso in this.state.chumps_dict) {
                date_to_use = past_date;
            }
            let date_str_iso = date_to_use.format('YYYY-MM-DD');

            this.setState({
                new_bout_mode: new_bout_modes.confirm_date,
                new_date: date_str_iso
            });
        }
        else {
            let { chumps_dict, chumps_changes, chump_dates } = this.state;
            let new_chump = JSON.parse(JSON.stringify(chump_template));
            new_chump.date = this.state.new_date;

            chumps_dict[this.state.new_date] = JSON.parse(JSON.stringify(new_chump));
            chumps_changes[this.state.new_date] = JSON.parse(JSON.stringify(new_chump));
            
            chump_dates.push(this.state.new_date)

            // Object.keys(chumps_dict).sort((a, b) => a.date < b.date);
            chump_dates.sort(function(a, b) {
                return (a < b) ? 1 : ((a > b) ? -1 : 0);
            });

            this.setState({
                selectedDate:this.state.new_date,
                chump_dates: chump_dates,
                chumps_dict: chumps_dict,
                chumps_changes: chumps_changes,
                new_bout_mode: new_bout_modes.new_bout,
            });

        }
    }

    onCancelButtonClick = () => {
        this.setState({
            new_bout_mode: new_bout_modes.new_bout
        });
    }

    onConfirmDateChange = (e) => {
        this.setState({
            new_date: e.target.value
        });
    }

    newBoutButtonArea = () => {
        if (this.state.new_bout_mode == new_bout_modes.new_bout) {
            return (
                <button type="button" class="btn btn-primary float-left" style={{ 'marginLeft': '0.5rem' }} onClick={this.onNewBoutButtonClick}>New Bout</button>
            )
        }
        else {
            return (
                <>
                    <button type="button" class="btn btn-primary float-left" style={{ 'marginLeft': '0.5rem', 'marginTop': '-4px', }} onClick={this.onNewBoutButtonClick} >Confirm Date</button>
                    <button type="button" class="btn btn-danger float-left" style={{ 'marginLeft': '0.5rem', 'marginTop': '-4px', }} onClick={this.onCancelButtonClick} >Cancel</button>
                    <input type="date" class="form-control" name="bout_date"
                        access="false" id="date-1658316014847" required="required"
                        aria-required="true" value={this.state.new_date}
                        style={{ width: 'auto', display: 'inline', marginLeft: '5px' }}
                        onChange={this.onConfirmDateChange}
                    />
                </>
            )
        }
    }

    render() {
        const { classes } = this.props;

        let display_image = this.getFieldValue(this.state.selectedDate, 'image')
        let display_thanks = this.getFieldValue(this.state.selectedDate, 'thanks')

        let display_values 


        return (
            <React.Fragment>
                <div className={classNames(classes.section)} style={{ width: '900px', height: '600px' }}>
                    <div style={{ 'width': '100%' }}>
                        <this.newBoutButtonArea />
                    </div>
                    <div className={classNames(classes.edit_container)}>
                        <div className={classNames(classes.flex_item1)}>
                            <select name="bouts" size="20" class="form-control"
                                onChange={this.onBoutListClick}
                                defaultValue={this.props.props.chumps[0].date}
                                value={this.state.selectedDate}
                            >
                                {
                                    this.state.chump_dates.map((date) => {
                                        let display_date = date;

                                        if (date in this.state.chumps_changes) {
                                            display_date += "*"
                                        }


                                        return (
                                            <option value={date}> {display_date} </option>
                                        );
                                    })
                                }

                            </select>
                        </div>
                        <div className={classNames(classes.flex_item2)}>
                            <div class="rendered-form">
                                <div class="formbuilder-date form-group field-date-1658316014847">
                                    <label for="date-1658316014847" class="formbuilder-date-label">Bout Date</label>
                                    <input type="date" class="form-control" name="bout_date"
                                        access="false" id="date-1658316014847" required="required"
                                        aria-required="true" value={this.state.selectedDate} />
                                </div>
                                <div class="formbuilder-text form-group field-text-1658315931444">
                                    <label for="text-1658315931444" class="formbuilder-text-label">Thanks {display_thanks.modified ? <>*</> : <></>}</label>
                                    <input type="text" class="form-control" name="text-1658315931444"
                                        access="false" id="text-1658315931444" required="required" aria-required="true"
                                        value={display_thanks.value}
                                        onChange={(e) => { this.addChumpChange('thanks', e.target.value); }}

                                    />
                                </div>
                                <div class="formbuilder-file form-group field-file-1658316344757">
                                    <label for="file-1658316344757" class="formbuilder-file-label">
                                        Image {display_image.modified ? <>*</> : <></>}
                                    </label>
                                    <input type="file" class="form-control" name="file-1658316344757" access="false"
                                        multiple id="file-1658316344757" required="required" aria-required="true"
                                        onChange={this.imageUpload}
                                    />
                                </div>
                                <div style={{ 'maxWidth': '100%', 'margin': '10px', display: 'inline' }}>
                                    <img style={{ 'width': '300px', boxShadow: '5px 10px 10px', display: 'block', margin: 'auto' }}
                                        src={display_image.value}
                                    >
                                    </img>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

            </React.Fragment>

        )
    }
}

EditChumpsLayout.propTypes = {
    classes: PropTypes.object.isRequired
};

/**
 * Map the actions to props.
 */
const mapDispatchToProps = dispatch => ({
    // actions: bindActionCreators(Object.assign({}, authService), dispatch)
});

const combinedStyles = combineStyles(frontPageStyle, commonStyle);

export default withStyles(combinedStyles)(EditChumpsLayout)
