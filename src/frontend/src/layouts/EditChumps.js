import React, { Component } from 'react';
// import {bindActionCreators} from 'redux'
// import {connect} from 'react-redux';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import classNames from 'classnames';

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

class FrontPage extends Component {
    constructor(props) {
        super(props);
        console.log(props)

        var chumps_dict = props.props.chumps.reduce((obj, item) => (obj[item.date] = item, obj), {});

        this.state = {
            chumps_array: props.props.chumps,
            chumps_dict: chumps_dict,
            selectedDate: props.props.chumps[0].date
        }
    }

    onBoutListClick = (e) => {
        console.log(this.state.chumps_dict[e.target.value])
        this.setState({
            selectedDate: e.target.value
        });
    }


    render() {
        const { classes } = this.props;

        return (
            <React.Fragment>
                <div className={classNames(classes.section)} style={{ width: '900px', height: '600px' }}>
                    <div style={{ 'width': '100%' }}>
                        <button type="button" class="btn btn-primary float-left" style={{'marginLeft': '0.5rem'}}>New Bout</button>
                    </div>
                    <div className={classNames(classes.edit_container)}>
                        <div className={classNames(classes.flex_item1)}>
                            <select name="bouts" size="20" class="form-control" onChange={this.onBoutListClick}>
                                {
                                    this.props.props.chumps.map((entry) => {
                                        return (
                                            <option value={entry.date}> {entry.date} </option>
                                        );
                                    })
                                }

                            </select>
                        </div>
                        <div className={classNames(classes.flex_item2)}>
                            <div class="rendered-form">
                                <div class="formbuilder-date form-group field-date-1658316014847">
                                    <label for="date-1658316014847" class="formbuilder-date-label">Bout Date<span class="formbuilder-required">*</span></label>
                                    <input type="date" class="form-control" name="bout_date"
                                        access="false" id="date-1658316014847" required="required"
                                        aria-required="true" value={this.state.selectedDate} />
                                </div>
                                <div class="formbuilder-text form-group field-text-1658315931444">
                                    <label for="text-1658315931444" class="formbuilder-text-label">Thanks<span class="formbuilder-required">*</span></label>
                                    <input type="text" class="form-control" name="text-1658315931444"
                                        access="false" id="text-1658315931444" required="required" aria-required="true"
                                        value={this.state.chumps_dict[this.state.selectedDate].thanks} />
                                </div>
                                <div class="formbuilder-file form-group field-file-1658316344757">
                                    <label for="file-1658316344757" class="formbuilder-file-label">Image<span class="formbuilder-required">*</span></label>
                                    <input type="file" class="form-control" name="file-1658316344757" access="false" multiple="false" id="file-1658316344757" required="required" aria-required="true" />
                                </div>
                                <div class="formbuilder-select form-group field-select-1658316619616">
                                    <label for="select-1658316619616" class="formbuilder-select-label">Select</label>
                                    <select class="form-control" name="select-1658316619616" id="select-1658316619616">
                                        <option value="option-1" selected="true" id="select-1658316619616-0">Option 1</option>
                                        <option value="option-2" id="select-1658316619616-1">Option 2</option>
                                        <option value="option-3" id="select-1658316619616-2">Option 3</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

            </React.Fragment>

        )
    }
}

FrontPage.propTypes = {
    classes: PropTypes.object.isRequired
};

/**
 * Map the actions to props.
 */
const mapDispatchToProps = dispatch => ({
    // actions: bindActionCreators(Object.assign({}, authService), dispatch)
});

const combinedStyles = combineStyles(frontPageStyle, commonStyle);

export default withStyles(combinedStyles)(FrontPage)
