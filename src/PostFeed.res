let s = React.string
@val external window: {..} = "window"

open Belt

type state = {posts: array<Post.t>, forDeletion: Map.String.t<Js.Global.timeoutId>}

type action =
  | DeleteLater(Post.t, Js.Global.timeoutId)
  | DeleteAbort(Post.t)
  | DeleteNow(Post.t)

let reducer = (state, action) =>
  switch action {
  | DeleteLater(post, timeoutId) => {
      ...state,
      forDeletion: Map.String.set(state.forDeletion, post.id, timeoutId),
    }
  | DeleteAbort(post) => {
      ...state,
      forDeletion: Belt.Map.String.remove(state.forDeletion, post.id),
    }
  | DeleteNow(post) => {
      posts: Js.Array.filter(p => p->Post.id != post.id, state.posts),
      forDeletion: Belt.Map.String.remove(state.forDeletion, post.id),
    }
  }

let initialState = {posts: Post.examples, forDeletion: Map.String.empty}

module MyPost = {
  @react.component
  let make = (~post: Post.t, ~dispatch, ~clearTimeout) => {
    let (toBeDeleted, setToBeDeleted) = React.useState(() => false)
    if !toBeDeleted {
      <div className="max-w-3xl mx-auto mt-8 relative">
        <div
          className="bg-green-700 hover:bg-green-900 text-gray-300 hover:text-gray-100 px-8 py-4 mb-4">
          <h2 className="text-2xl mb-1"> {s(post.title)} </h2>
          <h3 className="mb-4"> {s(post.author)} </h3>
          {post.text
          ->Array.map(text_line => {
            <p className="mb-1 text-sm"> {s(text_line)} </p>
          })
          ->React.array}
          <button
            className="mr-4 mt-4 bg-red-500 hover:bg-red-900 text-white py-2 px-4"
            onClick={_ => {
              dispatch(
                DeleteLater(post, window["setTimeout"](() => {dispatch(DeleteNow(post))}, 10000)),
              )
              setToBeDeleted(_ => true)
            }}>
            {s("Remove this post")}
          </button>
        </div>
      </div>
    } else {
      <div className="relative bg-yellow-100 px-8 py-4 mb-4 h-40 max-w-3xl mx-auto mt-8 relative">
        <p className="text-center white mb-1">
          {s(
            "This post from" ++
            post.title ++
            "by " ++
            post.author ++ "will be permanently removed in 10 seconds.",
          )}
        </p>
        <div className="flex justify-center">
          <button
            className="mr-4 mt-4 bg-yellow-500 hover:bg-yellow-900 text-white py-2 px-4"
            onClick={_ => {
              clearTimeout(post)
              setToBeDeleted(_ => {false})
            }}>
            {s("Restore")}
          </button>
          <button
            className="mr-4 mt-4 bg-red-500 hover:bg-red-900 text-white py-2 px-4"
            onClick={_ => {
              clearTimeout(post)
              dispatch(DeleteNow(post))
              setToBeDeleted(_ => false)
            }}>
            {s("Delete Immediately")}
          </button>
        </div>
        <div className="bg-red-500 h-2 w-full absolute top-0 left-0 progress" />
      </div>
    }
  }
}

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(reducer, initialState)

  let clearTimeout = (post: Post.t) => {
    state.forDeletion->Map.String.get(post.id)->Option.map(window["clearTimeout"])->ignore
  }

  <div className="bg-green-200 px-8 py-10 min-h-screen">
    <div className="space-y-8">
      {state.posts
      ->Belt.Array.map(postData => {
        <MyPost key=postData.id post=postData dispatch clearTimeout />
      })
      ->React.array}
    </div>
  </div>
}
