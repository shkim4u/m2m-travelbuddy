import React from "react";
import {BrowserRouter as Router, Route} from "react-router-dom";
import App from "./App";
import Header from "./components/layout/header/Header";

const Root = () => {
    return (
        <Router>
            <Header />
            <App />
        </Router>
    )
}

export default Root;
