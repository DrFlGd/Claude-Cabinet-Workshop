// Static deployments may live under a repository subpath. Sites uses root paths.
export function assetUrl(path:string){
 const base=typeof document==='undefined'?'http://localhost/':document.baseURI;
 return new URL(path.replace(/^\//,''),base).href;
}
