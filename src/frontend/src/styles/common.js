
const commonStyle = theme => ({
    section: {
        // background-color: var(--section-bg-color);
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        marginLeft: '8px',
        marginRight: '8px',
        padding: '8px',
        boxShadow: '2px 2px 2px 2px rgba(170, 170, 170, 0.67)',
        marginBottom: '8px',
        backgroundColor: '#FFF',
    },

    sectionWidth: {
        maxWidth: '600px',
        width: '100%',
        [theme.breakpoints.up('xs')]: {
            marginLeft: '10px',
            marginRight: '10px',
        },
        [theme.breakpoints.up('md')]: {
            'marginLeft': 'auto',
            'marginRight': 'auto',

        },
    },

    commonHeaderText: {
        fontSize: '5vw',

        [theme.breakpoints.up('sm')]: {
            fontSize: '1.5em',
        },
    },
    commonBigText: {
        fontSize: '100%',
        [theme.breakpoints.up('sm')]: {
            fontSize: '100%',
        },
    },
    commonRegularText: {
        fontSize: '3vw',

        [theme.breakpoints.up('sm')]: {
            fontSize: '1em',
        },
    },
    commonSmallText: {
        fontSize: '2vw',

        [theme.breakpoints.up('sm')]: {
            fontSize: '1em',
        },
    },

    sectionWidth: {
        maxWidth: '600px',
        width: '100%',
        [theme.breakpoints.up('xs')]: {
            marginLeft: '10px',
            marginRight: '10px',
        },
        [theme.breakpoints.up('md')]: {
            'marginLeft': 'auto',
            'marginRight': 'auto',

        },
    },

    edit_container: {
        display: 'flex',
        flexDirection: 'row',
        flexWrap: 'nowrap',
        justifyContent: 'normal',
        alignItems: 'normal',
        alignContent: 'normal',
        width:'100%',



      },
      flex_item1: {
        display: 'block',
        flexGrow: 1,
        flexShrink: 1,
        flexBasis: 'auto',
        alignSelf: 'auto',
        order: 0,
        margin: '0.5rem'
      },
      
      flex_item2: {
        display: 'block',
        flexGrow: 9,
        flexShrink: 1,
        flexBasis: 'auto',
        alignSelf: 'auto',
        order: 0,
      }


});
export default commonStyle;

// function applyCommonTheme(themeObject, otherTheme){
//     return Object.assign({}, otherTheme, commonTheme(themeObject));
// }
//
// export default applyCommonTheme