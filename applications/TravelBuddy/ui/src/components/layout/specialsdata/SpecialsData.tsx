import {Component} from "react";

class SpecialsData extends Component {
    render() {
        console.log("SpecialsData render().");
        return (
            <>
                {/*TravelBuddy Specials (Hotels & Flight) Data*/}
                <div className="container marketing">
                    <div className="row block flightdestinationblock">
                        <div className="col-md-6">
                            <h2>Today's flight specials</h2>
                            TODO: Add data retrieval logics here!
                        </div>

                        <div className="col-md-6">
                            <h2>Today's hotel specials</h2>
                            TODO: Add data retrieval logics here!
                        </div>
                    </div>
                </div>
            </>
        );
    }
}

export default SpecialsData;
