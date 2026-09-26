import React from 'react';
import {createRoot} from 'react-dom/client';
import Home from '../app/page';
import '../app/globals.css';
class StartupBoundary extends React.Component<React.PropsWithChildren,{error:string|null}>{
 state:{error:string|null}={error:null};
 static getDerivedStateFromError(error:Error){return {error:error.message};}
 render(){return this.state.error?<main role="alert"><h1>Cabinet Workshop could not start</h1><pre>{this.state.error}</pre><button onClick={()=>location.reload()}>Reload</button></main>:this.props.children;}
}
createRoot(document.getElementById('root')!).render(<StartupBoundary><Home/></StartupBoundary>);
