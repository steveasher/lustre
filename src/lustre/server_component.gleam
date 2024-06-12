//// > **Note**: server components are currently only supported on the **erlang**
//// > target. If it's important to you that they work on the javascript target,
//// > [open an issue](https://github.com/lustre-labs/lustre/issues/new) and tell
//// > us why it's important to you!
////
//// Server components are an advanced feature that allows you to run entire
//// Lustre applications on the server. DOM changes are broadcasted to a small
//// client runtime and browser events are sent back to the server.
////
//// ```text
//// -- SERVER -----------------------------------------------------------------
////
////                  Msg                            Element(Msg)
//// +--------+        v        +----------------+        v        +------+
//// |        | <-------------- |                | <-------------- |      |
//// | update |                 | Lustre runtime |                 | view |
//// |        | --------------> |                | --------------> |      |
//// +--------+        ^        +----------------+        ^        +------+
////         #(model, Effect(msg))  |        ^          Model
////                                |        |
////                                |        |
////                    DOM patches |        | DOM events
////                                |        |
////                                v        |
////                        +-----------------------+
////                        |                       |
////                        | Your WebSocket server |
////                        |                       |
////                        +-----------------------+
////                                |        ^
////                                |        |
////                    DOM patches |        | DOM events
////                                |        |
////                                v        |
//// -- BROWSER ----------------------------------------------------------------
////                                |        ^
////                                |        |
////                    DOM patches |        | DOM events
////                                |        |
////                                v        |
////                            +----------------+
////                            |                |
////                            | Client runtime |
////                            |                |
////                            +----------------+
//// ```
////
//// **Note**: Lustre's server component runtime is separate from your application's
//// WebSocket server. You're free to bring your own stack, connect multiple
//// clients to the same Lustre instance, or keep the application alive even when
//// no clients are connected.
////
//// Lustre server components run next to the rest of your backend code, your
//// services, your database, etc. Real-time applications like chat services, games,
//// or components that can benefit from direct access to your backend services
//// like an admin dashboard or data table are excellent candidates for server
//// components.
////
//// ## Examples
////
//// Server components are a new feature in Lustre and we're still working on the
//// best ways to use them and show them off. For now, you can find a simple
//// undocumented example in the `examples/` directory:
////
//// - [`99-server-components`](https://github.com/lustre-labs/lustre/tree/main/examples/99-server-components)
////
//// ## Getting help
////
//// If you're having trouble with Lustre or not sure what the right way to do
//// something is, the best place to get help is the [Gleam Discord server](https://discord.gg/Fm8Pwmy).
//// You could also open an issue on the [Lustre GitHub repository](https://github.com/lustre-labs/lustre/issues).
////

// IMPORTS ---------------------------------------------------------------------

import gleam/bool
import gleam/dynamic.{type DecodeError, type Dynamic, DecodeError, dynamic}
import gleam/erlang/process.{type Selector}
import gleam/int
import gleam/json.{type Json}
import gleam/result
import lustre.{type Patch, type ServerComponent}
import lustre/attribute.{type Attribute, attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element, element}
import lustre/internals/constants
import lustre/internals/patch
@target(erlang)
import lustre/internals/runtime.{type Action, Attrs, Event, SetSelector}
@target(javascript)
import lustre/internals/runtime.{type Action, Attrs, Event}

// ELEMENTS --------------------------------------------------------------------

/// Render the Lustre Server Component client runtime. The content of your server
/// component will be rendered inside this element.
///
/// **Note**: you must include the `lustre-server-component.mjs` script found in
/// the `priv/` directory of the Lustre package in your project's HTML or using
/// the [`script`](#script) function.
///
pub fn component(attrs: List(Attribute(msg))) -> Element(msg) {
  element("lustre-server-component", attrs, [])
}

/// Inline the Lustre Server Component client runtime as a script tag.
///
pub fn script() -> Element(msg) {
  element("script", [attribute("type", "module")], [
    // <<INJECT RUNTIME>>
    element.text(
      "function k(t,e,r,o=!1){let s,a=[{prev:t,next:e,parent:t.parentNode}];for(;a.length;){let{prev:n,next:i,parent:l}=a.pop();if(i.subtree!==void 0&&(i=i.subtree()),i.content!==void 0)if(n)if(n.nodeType===Node.TEXT_NODE)n.textContent!==i.content&&(n.textContent=i.content),s??=n;else{let c=document.createTextNode(i.content);l.replaceChild(c,n),s??=c}else{let c=document.createTextNode(i.content);l.appendChild(c),s??=c}else if(i.tag!==void 0){let c=D({prev:n,next:i,dispatch:r,stack:a,isComponent:o});n?n!==c&&l.replaceChild(c,n):l.appendChild(c),s??=c}else i.elements!==void 0?x(i,c=>{a.unshift({prev:n,next:c,parent:l}),n=n?.nextSibling}):i.subtree!==void 0&&a.push({prev:n,next:i,parent:l})}return s}function J(t,e,r){let o=t.parentNode;for(let s of e[0]){let a=s[0].split(\"-\"),n=s[1],i=N(o,a),l;if(i!==null&&i!==o)l=k(i,n,r);else{let c=N(o,a.slice(0,-1)),u=document.createTextNode(\"\");c.appendChild(u),l=k(u,n,r)}a===\"0\"&&(t=l)}for(let s of e[1]){let a=s[0].split(\"-\");N(o,a).remove()}for(let s of e[2]){let a=s[0].split(\"-\"),n=s[1],i=N(o,a),l=w.get(i);for(let c of n[0]){let u=c[0],m=c[1];if(u.startsWith(\"data-lustre-on-\")){let b=u.slice(15),p=r(M);l.has(b)||el.addEventListener(b,y),l.set(b,p),el.setAttribute(u,m)}else i.setAttribute(u,m),i[u]=m}for(let c of n[1])if(c[0].startsWith(\"data-lustre-on-\")){let u=c[0].slice(15);i.removeEventListener(u,y),l.delete(u)}else i.removeAttribute(c[0])}return t}function D({prev:t,next:e,dispatch:r,stack:o}){let s=e.namespace||\"http://www.w3.org/1999/xhtml\",a=t&&t.nodeType===Node.ELEMENT_NODE&&t.localName===e.tag&&t.namespaceURI===(e.namespace||\"http://www.w3.org/1999/xhtml\"),n=a?t:s?document.createElementNS(s,e.tag):document.createElement(e.tag),i;if(w.has(n))i=w.get(n);else{let d=new Map;w.set(n,d),i=d}let l=a?new Set(i.keys()):null,c=a?new Set(Array.from(t.attributes,d=>d.name)):null,u=null,m=null,b=null;for(let d of e.attrs){let f=d[0],h=d[1];if(d.as_property)n[f]!==h&&(n[f]=h),a&&c.delete(f);else if(f.startsWith(\"on\")){let g=f.slice(2),v=r(h);i.has(g)||n.addEventListener(g,y),i.set(g,v),a&&l.delete(g)}else if(f.startsWith(\"data-lustre-on-\")){let g=f.slice(15),v=r(M);i.has(g)||n.addEventListener(g,y),i.set(g,v),n.setAttribute(f,h)}else f===\"class\"?u=u===null?h:u+\" \"+h:f===\"style\"?m=m===null?h:m+h:f===\"dangerous-unescaped-html\"?b=h:(n.getAttribute(f)!==h&&n.setAttribute(f,h),(f===\"value\"||f===\"selected\")&&(n[f]=h),a&&c.delete(f))}if(u!==null&&(n.setAttribute(\"class\",u),a&&c.delete(\"class\")),m!==null&&(n.setAttribute(\"style\",m),a&&c.delete(\"style\")),a){for(let d of c)n.removeAttribute(d);for(let d of l)i.delete(d),n.removeEventListener(d,y)}if(e.key!==void 0&&e.key!==\"\")n.setAttribute(\"data-lustre-key\",e.key);else if(b!==null)return n.innerHTML=b,n;let p=n.firstChild,A=null,T=null,C=null,E=e.children[Symbol.iterator]().next().value;a&&E!==void 0&&E.key!==void 0&&E.key!==\"\"&&(A=new Set,T=L(t),C=L(e));for(let d of e.children)x(d,f=>{f.key!==void 0&&A!==null?p=W(p,f,n,o,C,T,A):(o.unshift({prev:p,next:f,parent:n}),p=p?.nextSibling)});for(;p;){let d=p.nextSibling;n.removeChild(p),p=d}return n}var w=new WeakMap;function y(t){let e=t.currentTarget;if(!w.has(e)){e.removeEventListener(t.type,y);return}let r=w.get(e);if(!r.has(t.type)){e.removeEventListener(t.type,y);return}r.get(t.type)(t)}function M(t){let e=t.currentTarget,r=e.getAttribute(`data-lustre-on-${t.type}`),o=JSON.parse(e.getAttribute(\"data-lustre-data\")||\"{}\"),s=JSON.parse(e.getAttribute(\"data-lustre-include\")||\"[]\");switch(t.type){case\"input\":case\"change\":s.push(\"target.value\");break}return{tag:r,data:s.reduce((a,n)=>{let i=n.split(\".\");for(let l=0,c=a,u=t;l<i.length;l++)l===i.length-1?c[i[l]]=u[i[l]]:(c[i[l]]??={},u=u[i[l]],c=c[i[l]]);return a},{data:o})}}function L(t){let e=new Map;if(t)for(let r of t.children)x(r,o=>{let s=o?.key||o?.getAttribute?.(\"data-lustre-key\");s&&e.set(s,o)});return e}function N(t,e){let r,o,s=t;for(;[r,...o]=e,r!==void 0;)s=s.childNodes.item(r),e=o;return s}function W(t,e,r,o,s,a,n){for(;t&&!s.has(t.getAttribute(\"data-lustre-key\"));){let l=t.nextSibling;r.removeChild(t),t=l}if(a.size===0)return x(e,l=>{o.unshift({prev:t,next:l,parent:r}),t=t?.nextSibling}),t;if(n.has(e.key))return console.warn(`Duplicate key found in Lustre vnode: ${e.key}`),o.unshift({prev:null,next:e,parent:r}),t;n.add(e.key);let i=a.get(e.key);if(!i&&!t)return o.unshift({prev:null,next:e,parent:r}),t;if(!i&&t!==null){let l=document.createTextNode(\"\");return r.insertBefore(l,t),o.unshift({prev:l,next:e,parent:r}),t}return!i||i===t?(o.unshift({prev:t,next:e,parent:r}),t=t?.nextSibling,t):(r.insertBefore(i,t),o.unshift({prev:i,next:e,parent:r}),t)}function x(t,e){if(t.elements!==void 0)for(let r of t.elements)e(r);else e(t)}var O=class extends HTMLElement{static get observedAttributes(){return[\"route\"]}#n=null;#t=null;#e=null;constructor(){super(),this.#n=new MutationObserver(e=>{let r=[];for(let o of e)if(o.type===\"attributes\"){let{attributeName:s,oldValue:a}=o,n=this.getAttribute(s);if(a!==n)try{r.push([s,JSON.parse(n)])}catch{r.push([s,n])}}r.length&&this.#e?.send(JSON.stringify([5,r]))})}connectedCallback(){this.#t=document.createElement(\"div\"),this.appendChild(this.#t)}attributeChangedCallback(e,r,o){switch(e){case\"route\":if(!o)this.#e?.close(),this.#e=null;else if(r!==o){let s=this.getAttribute(\"id\"),a=o+(s?`?id=${s}`:\"\"),n=window.location.protocol===\"https:\"?\"wss\":\"ws\";this.#e?.close(),this.#e=new WebSocket(`${n}://${window.location.host}${a}`),this.#e.addEventListener(\"message\",i=>this.messageReceivedCallback(i))}}}messageReceivedCallback({data:e}){let[r,...o]=JSON.parse(e);switch(r){case 0:return this.diff(o);case 1:return this.emit(o);case 2:return this.init(o)}}init([e,r]){let o=[];for(let s of e)s in this?o.push([s,this[s]]):this.hasAttribute(s)&&o.push([s,this.getAttribute(s)]),Object.defineProperty(this,s,{get(){return this[`_${s}`]??this.getAttribute(s)},set(a){let n=this[s];typeof a==\"string\"?this.setAttribute(s,a):this[`_${s}`]=a,n!==a&&this.#e?.send(JSON.stringify([5,[[s,a]]]))}});this.#n.observe(this,{attributeFilter:e,attributeOldValue:!0,attributes:!0,characterData:!1,characterDataOldValue:!1,childList:!1,subtree:!1}),this.morph(r),o.length&&this.#e?.send(JSON.stringify([5,o]))}morph(e){this.#t=k(this.#t,e,r=>o=>{let s=r(o);this.#e?.send(JSON.stringify([4,s.tag,s.data]))})}diff([e]){this.#t=J(this.#t,e,r=>o=>{let s=r(o);this.#e?.send(JSON.stringify([4,s.tag,s.data]))})}emit([e,r]){this.dispatchEvent(new CustomEvent(e,{detail:r}))}disconnectedCallback(){this.#e?.close()}};window.customElements.define(\"lustre-server-component\",O);export{O as LustreServerComponent};",
    ),
  ])
}

// ATTRIBUTES ------------------------------------------------------------------

/// The `route` attribute tells the client runtime what route it should use to
/// set up the WebSocket connection to the server. Whenever this attribute is
/// changed (by a clientside Lustre app, for example), the client runtime will
/// destroy the current connection and set up a new one.
///
pub fn route(path: String) -> Attribute(msg) {
  attribute("route", path)
}

/// Ocassionally you may want to attach custom data to an event sent to the server.
/// This could be used to include a hash of the current build to detect if the
/// event was sent from a stale client.
///
/// Your event decoders can access this data by decoding `data` property of the
/// event object.
///
pub fn data(json: Json) -> Attribute(msg) {
  json
  |> json.to_string
  |> attribute("data-lustre-data", _)
}

/// Properties of a JavaScript event object are typically not serialisable. This
/// means if we want to pass them to the server we need to copy them into a new
/// object first.
///
/// This attribute tells Lustre what properties to include. Properties can come
/// from nested objects by using dot notation. For example, you could include the
/// `id` of the target `element` by passing `["target.id"]`.
///
/// ```gleam
/// import gleam/dynamic
/// import gleam/result.{try}
/// import lustre/element.{type Element}
/// import lustre/element/html
/// import lustre/event
/// import lustre/server
///
/// pub fn custom_button(on_click: fn(String) -> msg) -> Element(msg) {
///   let handler = fn(event) {
///     use target <- try(dynamic.field("target", dynamic.dynamic)(event))
///     use id <- try(dynamic.field("id", dynamic.string)(target))
///
///     Ok(on_click(id))
///   }
///
///   html.button([event.on_click(handler), server.include(["target.id"])], [
///     element.text("Click me!")
///   ])
/// }
/// ```
///
pub fn include(properties: List(String)) -> Attribute(msg) {
  properties
  |> json.array(json.string)
  |> json.to_string
  |> attribute("data-lustre-include", _)
}

// ACTIONS ---------------------------------------------------------------------

/// A server component broadcasts patches to be applied to the DOM to any connected
/// clients. This action is used to add a new client to a running server component.
///
pub fn subscribe(
  id: String,
  renderer: fn(Patch(msg)) -> Nil,
) -> Action(msg, ServerComponent) {
  runtime.Subscribe(id, renderer)
}

/// Remove a registered renderer from a server component. If no renderer with the
/// given id is found, this action has no effect.
///
pub fn unsubscribe(id: String) -> Action(msg, ServerComponent) {
  runtime.Unsubscribe(id)
}

// EFFECTS ---------------------------------------------------------------------

/// Instruct any connected clients to emit a DOM event with the given name and
/// data. This lets your server component communicate to frontend the same way
/// any other HTML elements do: you might emit a `"change"` event when some part
/// of the server component's state changes, for example.
///
/// This is a real DOM event and any JavaScript on the page can attach an event
/// listener to the server component element and listen for these events.
///
pub fn emit(event: String, data: Json) -> Effect(msg) {
  effect.event(event, data)
}

///
///
pub fn set_selector(sel: Selector(Action(runtime, msg))) -> Effect(msg) {
  do_set_selector(sel)
}

@target(erlang)
fn do_set_selector(sel: Selector(Action(runtime, msg))) -> Effect(msg) {
  use _ <- effect.from
  let self = process.new_subject()

  process.send(self, SetSelector(sel))
}

@target(javascript)
fn do_set_selector(_sel: Selector(Action(runtime, msg))) -> Effect(msg) {
  effect.none()
}

// DECODERS --------------------------------------------------------------------

/// The server component client runtime sends JSON encoded actions for the server
/// runtime to execute. Because your own WebSocket server sits between the two
/// parts of the runtime, you need to decode these actions and pass them to the
/// server runtime yourself.
///
pub fn decode_action(
  dyn: Dynamic,
) -> Result(Action(runtime, ServerComponent), List(DecodeError)) {
  dynamic.any([decode_event, decode_attrs])(dyn)
}

fn decode_event(dyn: Dynamic) -> Result(Action(runtime, msg), List(DecodeError)) {
  use #(kind, name, data) <- result.try(dynamic.tuple3(
    dynamic.int,
    dynamic,
    dynamic,
  )(dyn))
  use <- bool.guard(
    kind != constants.event,
    Error([
      DecodeError(
        path: ["0"],
        found: int.to_string(kind),
        expected: int.to_string(constants.event),
      ),
    ]),
  )
  use name <- result.try(dynamic.string(name))

  Ok(Event(name, data))
}

fn decode_attrs(dyn: Dynamic) -> Result(Action(runtime, msg), List(DecodeError)) {
  use #(kind, attrs) <- result.try(dynamic.tuple2(dynamic.int, dynamic)(dyn))
  use <- bool.guard(
    kind != constants.attrs,
    Error([
      DecodeError(
        path: ["0"],
        found: int.to_string(kind),
        expected: int.to_string(constants.attrs),
      ),
    ]),
  )
  use attrs <- result.try(dynamic.list(decode_attr)(attrs))

  Ok(Attrs(attrs))
}

fn decode_attr(dyn: Dynamic) -> Result(#(String, Dynamic), List(DecodeError)) {
  dynamic.tuple2(dynamic.string, dynamic)(dyn)
}

// ENCODERS --------------------------------------------------------------------

/// Encode a DOM patch as JSON you can send to the client runtime to apply. Whenever
/// the server runtime re-renders, all subscribed clients will receive a patch
/// message they must forward to the client runtime.
///
pub fn encode_patch(patch: Patch(msg)) -> Json {
  patch.patch_to_json(patch)
}
