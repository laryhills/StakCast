import React from 'react'

const CommentSection = () => {
  return (
    <div className="mt-8">
      <h2 className="text-xl font-semibold">Comments</h2>
      <div className="bg-gray-50 p-4 rounded-lg shadow-inner">
        <ul>
          <li className="text-gray-700 py-2 border-b">
            User123: This market looks promising!
          </li>
          <li className="text-gray-700 py-2 border-b">
            User456: I think the odds will shift soon.
          </li>
          <li className="text-gray-700 py-2">User789: Any updates on this?</li>
        </ul>
      </div>
      <div className="mt-4">
        <input
          type="text"
          placeholder="Add a comment..."
          className="w-full px-4 py-2 border rounded-lg shadow-inner"
        />
        <button className="mt-2 px-4 py-2 bg-green-600 text-white rounded-lg shadow-md hover:bg-green-700">
          Submit
        </button>
      </div>
    </div>
  );
}

export default CommentSection