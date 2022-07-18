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
        this.chumps = props.chumps

        this.state = {
        }
    }



    render() {
        const { classes } = this.props;

        return (
            <React.Fragment>
                <div className={classNames(classes.section)} style={{ width: '900px' }}>

                
                    <div className={classNames(classes.edit_container)}>

                        <div className={classNames(classes.flex_item1)}>item 1</div>
                        <div className={classNames(classes.flex_item2)}>item 2</div>

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
